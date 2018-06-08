//
//  CaptureOptionsViewController.swift
//  L-Systems
//
//  Created by Spizzace on 6/8/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class CaptureOptionsViewController: NSViewController {

    @IBOutlet var frameRateTextField: NSTextField!
    @IBOutlet var videoOutputPathTextField: FilePathTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.videoOutputPathTextField.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleVideoOutputPathClick(_:))))
    }
    
    @objc func handleVideoOutputPathClick(_ gesture: NSClickGestureRecognizer) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["mov"]
        panel.allowsOtherFileTypes = false
        panel.isExtensionHidden = false
        
        panel.begin { (response) in
            if response == NSApplication.ModalResponse.OK {
                self.videoOutputPathTextField.stringValue = panel.url!.path
            }
        }
    }
}
