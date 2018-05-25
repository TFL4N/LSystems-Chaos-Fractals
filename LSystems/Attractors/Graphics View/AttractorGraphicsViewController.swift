//
//  AttractorGraphicsViewController.swift
//  L-Systems
//
//  Created by Spizzace on 5/24/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//


import Cocoa
import MetalKit

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
        
        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
        self.mtkView.device = defaultDevice
        
        do {
            self.renderer = try AttractorRenderer(metalKitView: self.mtkView, attractor: self.attractor)
        } catch {
            print("Renderer cannot be initialized: \(error)")
            return
        }
        
        self.renderer.mtkView(self.mtkView, drawableSizeWillChange: mtkView.drawableSize)
        
        self.mtkView.delegate = self.renderer
        
        // Add Gestures
        /////////////////
        self.pinchGesture = NSMagnificationGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        self.panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        self.rotateGesture = NSRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        
        self.mtkView.addGestureRecognizer(self.pinchGesture)
        self.mtkView.addGestureRecognizer(self.panGesture)
        self.mtkView.addGestureRecognizer(self.rotateGesture)
    }
    
    // MARK: Panel Handlers
    @objc func handleSaveImagePress(_ notification: Notification) {
        print("Save Image Press")
    }
    
    // MARK: Gesture Handlers
    var lastScaleValue: CGFloat = 0.0
    var lastPanValue: CGPoint = CGPoint.zero
    var lastRotationValue: CGFloat = 0.0
    
    @objc func handlePinchGesture(_ gesture: NSMagnificationGestureRecognizer) {
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
