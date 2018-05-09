//
//  GameViewController.swift
//  L-Systems
//
//  Created by Spizzace on 3/28/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa
import MetalKit

// Our macOS specific view controller
class LGraphicsViewController: NSViewController {

    var renderer: Renderer!
    var mtkView: MTKView!

    var l_system: LSystem?
    
    var pinchGesture: NSMagnificationGestureRecognizer!
    var panGesture: NSPanGestureRecognizer!
    
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
            self.renderer = try Renderer(metalKitView: self.mtkView, l_system: self.l_system!)
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
        
        self.mtkView.addGestureRecognizer(self.pinchGesture)
        self.mtkView.addGestureRecognizer(self.panGesture)
    }
    
    // MARK: Gesture Handlers
    var lastScaleValue: CGFloat = 0.0
    var lastPanValue: CGPoint = CGPoint.zero
    
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
            
            self.renderer.transX += Float(translation.x - self.lastPanValue.x)
            self.renderer.transY += Float(translation.y - self.lastPanValue.y)
            
            self.lastPanValue = translation
        default:
            break
        }
    }
}
