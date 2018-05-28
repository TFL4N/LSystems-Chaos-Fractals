//
//  AttractorGraphicsViewController.swift
//  L-Systems
//
//  Created by Spizzace on 5/24/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//


import Cocoa
import MetalKit

class AttractorGraphicsViewController: AttractorDocumentViewController, AttractorRendererDelegate {
    var renderer: AttractorRenderer!
    var mtkView: MTKView!
    
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
            self.renderer = try AttractorRenderer(metalKitView: self.mtkView, delegate: self)
        } catch {
            print("Renderer cannot be initialized: \(error)")
            return
        }
        
        self.renderer.mtkView(self.mtkView, drawableSizeWillChange: mtkView.drawableSize)
        
        // Additional Configuration
        self.mtkView.delegate = self.renderer
        self.render_mode = .live
        
        // Add Gestures
        /////////////////
        self.pinchGesture = NSMagnificationGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        self.panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        self.rotateGesture = NSRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        
        self.mtkView.addGestureRecognizer(self.pinchGesture)
        self.mtkView.addGestureRecognizer(self.panGesture)
        self.mtkView.addGestureRecognizer(self.rotateGesture)
    }
    
    // MARK: Attractor Renderer Delegate
    func rendererDidDraw() {
        if self.render_mode == .video_capture {
            self.handleDidDraw_VideoCapture()
        }
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
        let file_name = String(format: "frame%05i.png", self.attractor_manager.current_frame)
        let url = URL(fileURLWithPath: "/Users/SpaiceMaine/GoodKarmaCoding/LSystems Documents/capture/\(file_name)")
        self.captureImage(destinationURL: url)
        
        self.attractor_manager.current_frame += 1
        
        if self.attractor_manager.current_frame < self.videoCaptureSettings.frame_count {
            self.mtkView.draw()
        }
    }
    
    func handleDidDraw_VideoCapture() {
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
                self.attractor_manager.current_frame,
                texture: self.mtkView.currentDrawable!.texture)
            
            self.attractor_manager.current_frame += 1
            
            if self.attractor_manager.current_frame < self.videoCaptureSettings.frame_count {
                self.mtkView.draw()
            } else {
                self.videoCaptureSettings.finishCapturingVideo()
            }
        }
    }

    // MARK: Renderer Mode
    var render_mode: RenderMode {
        get {
            return RenderMode(rawValue: self.render_mode_raw)!
        }
        
        set {
            self.render_mode_raw = newValue.rawValue
        }
    }
    
    @objc dynamic var render_mode_raw = RenderMode.live.rawValue {
        didSet {
            switch self.render_mode {
            case .video_capture:
                self.mtkView?.isPaused = true
                self.mtkView?.enableSetNeedsDisplay = false
                
            case .live:
                self.mtkView?.isPaused = false
                self.mtkView?.enableSetNeedsDisplay = false
                
            case .static:
                self.mtkView?.isPaused = true
                self.mtkView?.enableSetNeedsDisplay = false
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
        guard self.render_mode == .live else {
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
        guard self.render_mode == .live else {
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
        guard self.render_mode == .live else {
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
