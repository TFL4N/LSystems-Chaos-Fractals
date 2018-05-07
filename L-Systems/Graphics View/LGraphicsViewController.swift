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
        
        self.mtkView.addGestureRecognizer(self.pinchGesture)
    }
    
    // MARK: Gesture Handlers
    var lastScaleValue: CGFloat = 0.0
    
    @objc func handlePinchGesture(_ gesture: NSMagnificationGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.lastScaleValue = 0.0
        case .changed, .ended:
            self.renderer.scale += Float(gesture.magnification - self.lastScaleValue)
            self.lastScaleValue = gesture.magnification
        default:
            break
        }
    }
}
