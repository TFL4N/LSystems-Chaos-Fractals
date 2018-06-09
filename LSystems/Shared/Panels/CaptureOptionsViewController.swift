//
//  CaptureOptionsViewController.swift
//  L-Systems
//
//  Created by Spizzace on 6/8/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class CaptureOptionsViewController: NSViewController {
    
    @IBOutlet var frameCountTextField: NSTextField!
    @IBOutlet var frameCountStepper: NSStepper!

    @IBOutlet var frameRateTextField: NSTextField!
    @IBOutlet var frameRateStepper: NSStepper!
    
    @IBOutlet var videoWidthTextField: NSTextField!
    @IBOutlet var videoWidthStepper: NSStepper!
    
    @IBOutlet var videoHeightTextField: NSTextField!
    @IBOutlet var videoHeightStepper: NSStepper!
    
    @IBOutlet var videoOutputPathTextField: FilePathTextField!
    
    var document: AttractorDocument! {
        return self.parent?.view.window?.windowController?.document as? AttractorDocument
    }
    
    var video_capture_settings: VideoCaptureSettings! {
        return self.document.video_capture_settings
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.frameCountTextField.formatter = NumberFormatter.buildIntegerFormatter(min: 0, max: 1_000_000)
        self.frameRateTextField.formatter = NumberFormatter.buildIntegerFormatter(min: 0, max: 120)
        self.videoWidthTextField.formatter = NumberFormatter.buildIntegerFormatter(min: 0, max: 10_000)
        self.videoHeightTextField.formatter = NumberFormatter.buildIntegerFormatter(min: 0, max: 10_000)
        
        self.videoOutputPathTextField.allowedFileTypes = ["mov"]
        self.videoOutputPathTextField.handleDidSelectFileURL = { (_, url) in
            self.document.video_capture_settings.output_file_url = url
        }
    }
    
    private var needsBindings = true
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if self.needsBindings {
            self.needsBindings = false
            
            // frame count
            self.frameCountTextField.bind(.value,
                                          to: self.video_capture_settings,
                                          withKeyPath: "frame_count",
                                          options: nil)
            self.frameCountStepper.bind(.value,
                                        to: self.video_capture_settings,
                                        withKeyPath: "frame_count",
                                        options: nil)
            
            // frame rate
            self.frameRateTextField.bind(.value,
                                         to: self.video_capture_settings,
                                         withKeyPath: "frame_rate",
                                         options: nil)
            self.frameRateStepper.bind(.value,
                                       to: self.video_capture_settings,
                                       withKeyPath: "frame_rate",
                                       options: nil)
            
            // video width
            self.videoWidthTextField.bind(.value,
                                          to: self.video_capture_settings,
                                          withKeyPath: "video_width",
                                          options: nil)
            self.videoWidthStepper.bind(.value,
                                        to: self.video_capture_settings,
                                        withKeyPath: "video_width",
                                        options: nil)
            
            // video height
            self.videoHeightTextField.bind(.value,
                                           to: self.video_capture_settings,
                                           withKeyPath: "video_height",
                                           options: nil)
            self.videoHeightStepper.bind(.value,
                                         to: self.video_capture_settings,
                                         withKeyPath: "video_height",
                                         options: nil)
        }
        
        self.videoOutputPathTextField.fileURL = self.document.video_capture_settings.output_file_url
    }
    
    @IBAction func handleCaptureVideoPress(_: Any?) {
        self.document.captureVideo()
    }
}
