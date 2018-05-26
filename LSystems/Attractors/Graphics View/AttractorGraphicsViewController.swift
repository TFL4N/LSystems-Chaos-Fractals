//
//  AttractorGraphicsViewController.swift
//  L-Systems
//
//  Created by Spizzace on 5/24/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//


import Cocoa
import MetalKit
import AVFoundation

enum RendererMode: String {
    case live
    case videoCapture
}

typealias FrameId = UInt
typealias FrameInterval = UInt

enum VideoCaptureError: Error {
    case FailedToCreatePixelBuffer
    case FailedToCreatePixelBufferPool
    case FailedToGetPixelBufferPool
    case FailedToGetPixelBaseAddress
}

class VideoCapture {
    let frame_rate: UInt = 24
    let frame_count = 500
    let video_size: CGSize = CGSize(width: 1600, height: 1200)
    
    var video_writer: AVAssetWriter!
    var video_writer_input: AVAssetWriterInput!
    var pixel_buffer_adapter: AVAssetWriterInputPixelBufferAdaptor!
    
    var status: Status = .idle
    var error: Error? = nil
    
    private func destroy() {
        self.video_writer = nil
        self.video_writer_input = nil
        self.pixel_buffer_adapter = nil
    }
    
    func beginCapturingVideo()  {
        do {
            try self.createVideoAssetWriter()
            
            self.video_writer.startWriting()
            self.video_writer.startSession(atSourceTime: kCMTimeZero)
            
//            if self.pixel_buffer_adapter.pixelBufferPool == nil {
//                throw VideoCaptureError.FailedToCreatePixelBufferPool
//            }
            
            self.status = .capturing
        } catch {
            print("beginCapturingVideo Fail: \(error)")
            
            self.error = error
            self.status = .error
            
            self.destroy()
            return
        }
    }
    
    func appendFrame(_ frame: FrameId, texture: MTLTexture) {
        guard self.status == .capturing else {
            print("Trying to append frame while not capturing")
            return
        }
        
        do {
            try self.append(frame, texture: texture)
        } catch {
            self.error = error
            self.status = .error
            
            self.video_writer_input.markAsFinished()
            self.video_writer.finishWriting {
              self.destroy()
            }
        }
    }
    
    func finishCapturingVideo() {
        self.video_writer_input.markAsFinished()
        self.video_writer.finishWriting {
            if let err = self.video_writer.error {
                print("Video Writing Complete: \(err)")
                self.error = err
                self.status = .error
            } else {
                print("Video Writing Complete")
                self.status = .done
            }
            
            self.destroy()
        }
    }
    
    private func createVideoAssetWriter() throws {
        let output_url = URL(fileURLWithPath: "/Users/SpaiceMaine/GoodKarmaCoding/LSystems Documents/capture/video.mov")
        
        // create writer
        do {
            self.video_writer = try AVAssetWriter(outputURL: output_url, fileType: .mov)
        } catch {
            print("Failed to create AVAssetWriter: \(error)")
            throw error
        }
        
        // create input
        let settings: [String:Any] = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : self.video_size.width,
            AVVideoHeightKey : self.video_size.height
        ]
        self.video_writer_input = AVAssetWriterInput(mediaType: .video,
                                                   outputSettings: settings)
        self.video_writer_input.expectsMediaDataInRealTime = false
        self.video_writer.add(self.video_writer_input)
        
        // buffer adapter
        let sourceBufferAttributes : [String : AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String : NSNumber(value: Int(self.video_size.width)),
            kCVPixelBufferHeightKey as String : NSNumber(value: Int(self.video_size.height)),
            ]
        self.pixel_buffer_adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.video_writer_input, sourcePixelBufferAttributes: sourceBufferAttributes)
    }
    
    private func append(_ frame: FrameId, texture: MTLTexture) throws {
        // Wait for input to be ready
        while !self.video_writer_input.isReadyForMoreMediaData {
            usleep(10_000)
        }
        
        try autoreleasepool {
            // Get Pixel Buffer
            /////////////
//            guard let pixel_buffer_pool = self.pixel_buffer_adapter.pixelBufferPool else {
//                throw VideoCaptureError.FailedToGetPixelBufferPool
//            }

            let pixel_buffer_ptr = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
            defer {
                pixel_buffer_ptr.deallocate()
            }
            
            guard CVPixelBufferCreate(kCFAllocatorDefault,
                                      Int(self.video_size.width),
                                      Int(self.video_size.height),
                                      kCVPixelFormatType_32BGRA,
                                      nil,
                                      pixel_buffer_ptr) == kCVReturnSuccess,
                let pixel_buffer = pixel_buffer_ptr.pointee else {
                    throw VideoCaptureError.FailedToCreatePixelBuffer
            }
            
            // Get Pixel Data
            ////////////////////
            CVPixelBufferLockBaseAddress(pixel_buffer, CVPixelBufferLockFlags.init(rawValue: 0))
            defer {
                CVPixelBufferUnlockBaseAddress(pixel_buffer, CVPixelBufferLockFlags.init(rawValue: 0))
            }
            
            guard let base_buffer = CVPixelBufferGetBaseAddress(pixel_buffer) else {
                throw VideoCaptureError.FailedToGetPixelBaseAddress
            }
            texture.getBytes(base_buffer,
                             bytesPerRow: CVPixelBufferGetBytesPerRow(pixel_buffer),
                             from: MTLRegionMake2D(0, 0, texture.width, texture.height),
                             mipmapLevel: 0)
            
            // Append Pixel Data
            //////////////////////
            let frame_duration = CMTimeMake(1, Int32(self.frame_rate))
            let time = CMTimeMultiply(frame_duration, Int32(frame))
            self.pixel_buffer_adapter.append(pixel_buffer, withPresentationTime: time)
        }
    }
    
    enum Status {
        case idle, capturing, done, error
    }
}

class AttractorGraphicsViewController: NSViewController {
    
    var renderer: AttractorRenderer!
    var mtkView: MTKView!
    
    var attractor: Attractor!
    
    var pinchGesture: NSMagnificationGestureRecognizer!
    var panGesture: NSPanGestureRecognizer!
    var rotateGesture: NSRotationGestureRecognizer!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleSaveImagePress(_:)), name: Notifications.SaveImagePressNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Metal View
        /////////////////////
        guard let mtkView = self.view as? MTKView else {
            print("View attached to GameViewController is not an MTKView")
            return
        }
        
        self.mtkView = mtkView
        self.mtkView.framebufferOnly = false
        
        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
        self.mtkView.device = defaultDevice
        
        // Create the Renderer
        do {
            self.renderer = try AttractorRenderer(metalKitView: self.mtkView, attractor: self.attractor)
        } catch {
            print("Renderer cannot be initialized: \(error)")
            return
        }
        
        self.renderer.mtkView(self.mtkView, drawableSizeWillChange: mtkView.drawableSize)
        
        // Additional Configuration
        self.mtkView.delegate = self.renderer
        self.rendererMode = .videoCapture
        
        // Add Gestures
        /////////////////
        self.pinchGesture = NSMagnificationGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        self.panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        self.rotateGesture = NSRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        
        self.mtkView.addGestureRecognizer(self.pinchGesture)
        self.mtkView.addGestureRecognizer(self.panGesture)
        self.mtkView.addGestureRecognizer(self.rotateGesture)
    }
    
    // MARK: Video Capture
    var videoCaptureSettings = VideoCapture()
   
    func captureImage(destinationURL: URL) {
        // get image from metal
        guard let image = self.mtkView.currentDrawable!.texture.toImage() else {
            print("Failed to get image from texture")
            return
        }
        
        // write image
        guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypePNG, 1, nil) else {
            print("Failed to create image destination")
            return
        }
        CGImageDestinationAddImage(destination, image, nil)
        if CGImageDestinationFinalize(destination) {
            print("Successly Created Image: \(destinationURL)")
        } else {
            print("Failed to create image")
        }
    }
    
    func handleCaptureImage() {
        let file_name = String(format: "frame%05i.png", self.renderer.attractor_manager.current_frame)
        let url = URL(fileURLWithPath: "/Users/SpaiceMaine/GoodKarmaCoding/LSystems Documents/capture/\(file_name)")
        self.captureImage(destinationURL: url)
        
        self.renderer.attractor_manager.current_frame += 1
        
        if self.renderer.attractor_manager.current_frame < self.videoCaptureSettings.frame_count {
            self.mtkView.draw()
        }
    }
    
    func handleDidDraw() {
        switch self.videoCaptureSettings.status {
        case .error, .done:
            return
        case .idle:
            self.videoCaptureSettings.beginCapturingVideo()
            
            print("Drawable: \(self.mtkView.drawableSize)")
            
            if self.videoCaptureSettings.status == .capturing {
                fallthrough
            }
        case .capturing:
            // append frame
            self.videoCaptureSettings.appendFrame(
                self.renderer.attractor_manager.current_frame,
                texture: self.mtkView.currentDrawable!.texture)
            
            self.renderer.attractor_manager.current_frame += 1
            
            if self.renderer.attractor_manager.current_frame < self.videoCaptureSettings.frame_count {
                self.mtkView.draw()
            } else {
                self.videoCaptureSettings.finishCapturingVideo()
            }
        }
    }

    
    // MARK: Renderer Mode
    var rendererMode: RendererMode = .videoCapture {
        didSet {
            switch self.rendererMode {
            case .videoCapture:
                self.mtkView?.isPaused = true
                self.mtkView?.enableSetNeedsDisplay = false
                self.renderer?.rendererDidDraw = self.handleDidDraw
                
            case .live:
                self.mtkView?.isPaused = false
                self.mtkView?.enableSetNeedsDisplay = false
                self.renderer?.rendererDidDraw = nil
            }
        }
    }
    
    // MARK: Panel Handlers
    @objc func handleSaveImagePress(_ notification: Notification) {
        self.mtkView.draw()
    }
    
    // MARK: Gesture Handlers
    var lastScaleValue: CGFloat = 0.0
    var lastPanValue: CGPoint = CGPoint.zero
    var lastRotationValue: CGFloat = 0.0
    
    @objc func handlePinchGesture(_ gesture: NSMagnificationGestureRecognizer) {
        guard self.rendererMode != .videoCapture else {
            return
        }
        
        switch gesture.state {
        case .began:
            self.lastScaleValue = 0.0
        case .changed, .ended:
            let new_scale = self.renderer.scale + Float(gesture.magnification - self.lastScaleValue)
            self.renderer.scale = max(new_scale, 0.0001)
            
            self.lastScaleValue = gesture.magnification
        default:
            break
        }
        
    }
    
    @objc func handlePanGesture(_ gesture: NSPanGestureRecognizer) {
        guard self.rendererMode != .videoCapture else {
            return
        }
        
        switch gesture.state {
        case .began:
            self.lastPanValue = CGPoint.zero
        case .changed, .ended:
            let translation = gesture.translation(in: gesture.view)
            
            let new_x = Float(translation.x - self.lastPanValue.x)
            let new_y = Float(translation.y - self.lastPanValue.y)
            self.renderer.addTranslationWithAdjustment((x: new_x, y: new_y))
            
            self.lastPanValue = translation
        default:
            break
        }
    }
    
    @objc func handleRotationGesture(_ gesture: NSRotationGestureRecognizer) {
        guard self.rendererMode != .videoCapture else {
            return
        }
        
        switch gesture.state {
        case .began:
            self.lastRotationValue = 0.0
        case .changed, .ended:
            let new_rotation = self.renderer.rotation + Float(gesture.rotation - self.lastRotationValue)
            self.renderer.rotation = new_rotation
            
            self.lastRotationValue = gesture.rotation
        default:
            break
        }
    }
}
