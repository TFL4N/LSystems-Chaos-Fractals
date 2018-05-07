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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MTKView else {
            print("View attached to GameViewController is not an MTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }

        mtkView.device = defaultDevice

        do {
            self.renderer = try Renderer(metalKitView: mtkView, l_system: self.l_system!)
        } catch {
            print("Renderer cannot be initialized: \(error)")
            return
        }

        self.renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = self.renderer
    }
}
