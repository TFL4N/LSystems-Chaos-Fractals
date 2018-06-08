//
//  VideoCapture.swift
//  L-Systems
//
//  Created by Spizzace on 5/27/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import AVFoundation
import MetalKit

typealias FrameId = UInt
typealias FrameInterval = UInt

enum VideoCaptureError: Error {
    case FailedToCreatePixelBuffer
    case FailedToCreatePixelBufferPool
    case FailedToGetPixelBufferPool
    case FailedToGetPixelBaseAddress
    
    case FailedToCreateMTLDevice
}

class VideoCaptureSettings: NSObject, NSCoding {
    static let default_frame_count: UInt = 500
    static let default_frame_rate: UInt = 24
    static let default_video_size: CGSize = CGSize(width: 1600, height: 1200)
    
    @objc dynamic var frame_count: UInt
    @objc dynamic var frame_rate: UInt
    @objc dynamic var video_size: CGSize
    var output_file_url: URL?
    
    @objc dynamic var video_width: UInt {
        get {
            return UInt(self.video_size.width)
        }
        
        set {
            self.video_size.width = CGFloat(newValue)
        }
    }
    
    @objc dynamic var video_height: UInt {
        get {
            return UInt(self.video_size.height)
        }
        
        set {
            self.video_size.height = CGFloat(newValue)
        }
    }
    
    init(frame_count: UInt = VideoCaptureSettings.default_frame_count,
         frame_rate: UInt = VideoCaptureSettings.default_frame_rate,
         video_size: CGSize = VideoCaptureSettings.default_video_size,
         output_file_url: URL? = nil) {
        self.frame_count = frame_count
        self.frame_rate = frame_rate
        self.video_size = video_size
        self.output_file_url = output_file_url
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let coder = aDecoder as! NSKeyedArchiver
        
        var frame_count = UInt(coder.decodeInteger(forKey: "video_capture_settings_frame_count"))
        frame_count = frame_count == 0 ? VideoCaptureSettings.default_frame_count : frame_count
        
        var frame_rate = UInt(coder.decodeInteger(forKey: "video_capture_settings_frame_rate"))
        frame_rate = frame_rate == 0 ? VideoCaptureSettings.default_frame_rate : frame_rate
        
        var video_size = coder.decodeSize(forKey: "video_capture_settings_video_size")
        video_size = video_size == NSSize.zero ? VideoCaptureSettings.default_video_size : video_size
        
        let output_path_str = coder.decodeObject(forKey: "video_capture_settings_output_path") as? String
        var output_path_url: URL? = nil
        if let str = output_path_str {
           output_path_url = URL(string: str)
        }
        
        self.init(frame_count: frame_count, frame_rate: frame_rate, video_size: video_size, output_file_url: output_path_url)
    }
    
    func encode(with aCoder: NSCoder) {
        let coder = aCoder as! NSKeyedArchiver
        
        coder.encode(self.frame_count, forKey: "video_capture_settings_frame_count")
        coder.encode(self.frame_rate, forKey: "video_capture_settings_frame_rate")
        coder.encode(self.video_size, forKey: "video_capture_settings_video_size")
        coder.encode(self.output_file_url?.absoluteString, forKey: "video_capture_settings_output_path")
    }
}

class VideoCapture: AttractorRendererDelegate {
    let attractor_manager: AttractorManager!
    let settings: VideoCaptureSettings
    
    var mtkView: MTKView!
    var renderer: AttractorRenderer!
    
    var video_writer: AVAssetWriter!
    var video_writer_input: AVAssetWriterInput!
    var pixel_buffer_adapter: AVAssetWriterInputPixelBufferAdaptor!
    
    var status: Status = .idle
    var error: Error? = nil
    
    enum Status {
        case idle, capturing, done, error
    }
    
    init(attractor: Attractor, settings: VideoCaptureSettings) {
        self.attractor_manager = AttractorManager(attractor: attractor)
        self.settings = settings.deepCopy()
    }
    
    private func destroy() {
        self.video_writer = nil
        self.video_writer_input = nil
        self.pixel_buffer_adapter = nil
    }
    
    func beginCapturingVideo() -> Bool  {
        do {
            try self.createRenderer()
            try self.createVideoAssetWriter()
            
            self.video_writer.startWriting()
            self.video_writer.startSession(atSourceTime: kCMTimeZero)
            
            //            if self.pixel_buffer_adapter.pixelBufferPool == nil {
            //                throw VideoCaptureError.FailedToCreatePixelBufferPool
            //            }
            
            self.status = .capturing
            
            self.mtkView.draw()
            
            return true
        } catch {
            print("beginCapturingVideo Fail: \(error)")
            
            self.error = error
            self.status = .error
            
            self.destroy()
            return false
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
    
    private func createRenderer() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw VideoCaptureError.FailedToCreateMTLDevice
        }
        self.mtkView = MTKView(frame: CGRect(origin: CGPoint.zero, size: self.settings.video_size), device: device)
        self.mtkView.isPaused = true
        self.mtkView.enableSetNeedsDisplay = false
        
        self.renderer = try AttractorRenderer(metalKitView: self.mtkView, delegate: self)
        
        self.mtkView.delegate = self.renderer
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
            AVVideoWidthKey : self.settings.video_size.width,
            AVVideoHeightKey : self.settings.video_size.height
        ]
        self.video_writer_input = AVAssetWriterInput(mediaType: .video,
                                                     outputSettings: settings)
        self.video_writer_input.expectsMediaDataInRealTime = false
        self.video_writer.add(self.video_writer_input)
        
        // buffer adapter
        let sourceBufferAttributes : [String : AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String : NSNumber(value: Int(self.settings.video_size.width)),
            kCVPixelBufferHeightKey as String : NSNumber(value: Int(self.settings.video_size.height)),
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
                                      Int(self.settings.video_size.width),
                                      Int(self.settings.video_size.height),
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
            let frame_duration = CMTimeMake(1, Int32(self.settings.frame_rate))
            let time = CMTimeMultiply(frame_duration, Int32(frame))
            self.pixel_buffer_adapter.append(pixel_buffer, withPresentationTime: time)
        }
    }
    
    // MARK: - Renderer Delegate
    func rendererDidDraw() {
        switch self.status {
        case .error, .done, .idle:
            return
        case .capturing:
            // append frame
            self.appendFrame(
                self.attractor_manager.current_frame,
                texture: self.mtkView.currentDrawable!.texture)
            
            self.attractor_manager.current_frame += 1
            
            if self.attractor_manager.current_frame < self.settings.frame_count {
                self.mtkView.draw()
            } else {
                self.finishCapturingVideo()
            }
        }
    }
    
    func dataBuildProgress(_: Float) {
        
    }
    
    func dataBuildDidStart() {
        
    }
    
    func dataBuildDidFinished(wasCancelled: Bool) {
        
    }
}
