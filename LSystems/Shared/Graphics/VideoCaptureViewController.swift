//
//  VideoCaptureViewController.swift
//  L-Systems
//
//  Created by Spizzace on 6/8/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

protocol VideoCaptureViewControllerDelegate {
    func handleClosePress(_: VideoCaptureViewController)
}

class VideoCaptureViewController: NSViewController, VideoCaptureDelegate {
    @IBOutlet var frameProgressView: ProgressView!
    @IBOutlet var overallProgressView: ProgressView!
    @IBOutlet var messageLabel: NSTextField!
    @IBOutlet var cancelButton: NSButton!
    
    var delegate: VideoCaptureViewControllerDelegate? = nil
    
    var video_capture: VideoCapture! {
        didSet {
            self.video_capture.delegate = self
            
            if self.isViewLoaded {
                let _ = self.video_capture.beginCapturingVideo()
            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if self.video_capture.status == .idle {
            let _ = self.video_capture.beginCapturingVideo()
        }
    }
    
    @IBAction func handleCancelPress(_: Any?) {
        if self.cancelButton.title == "Cancel" {
            self.video_capture.cancelCapturingVideo()
        } else {
            self.delegate?.handleClosePress(self)
        }
    }
    
    // MARK: Video Capture Delegate
    private func updateProgressViews(frame: FrameId, frameProgress: Double, frameElapsedTime: TimeInterval, frameRemainingTime: TimeInterval, overallProgress: Double, overallElapsedTime: TimeInterval, overallTimeRemaining: TimeInterval) {
        DispatchQueue.main.async {
            self.showMessage("Frame \(frame+1) of \(self.video_capture.settings.frame_count)")
            self.overallProgressView.setProgess(overallProgress, elapsedTime: overallElapsedTime, remainingTime: overallTimeRemaining)
            
            self.frameProgressView.setProgess(frameProgress, elapsedTime: frameElapsedTime, remainingTime: frameRemainingTime)
        }
    }
    
    private func showMessage(_ str: String) {
        self.messageLabel.stringValue = str
        self.messageLabel.isHidden = false
    }
    
    func captureDidBegin(_: VideoCapture) {
        self.updateProgress(frame: 0,
                            frameProgress: 0.0,
                            frameElapsedTime: 0.0,
                            frameRemainingTime: 0.0,
                            overallProgress: 0.0,
                            overallElapsedTime: 0.0,
                            overallTimeRemaining: 0.0)
    }
    
    func updateProgress(frame: FrameId, frameProgress: Double, frameElapsedTime: TimeInterval, frameRemainingTime: TimeInterval, overallProgress: Double, overallElapsedTime: TimeInterval, overallTimeRemaining: TimeInterval) {
        
        self.updateProgressViews(frame: frame,
                            frameProgress: frameProgress,
                            frameElapsedTime: frameElapsedTime,
                            frameRemainingTime: frameRemainingTime,
                            overallProgress: overallProgress,
                            overallElapsedTime: overallElapsedTime,
                            overallTimeRemaining: overallTimeRemaining)
    }
    
    func captureDidComplete(_: VideoCapture) {
        DispatchQueue.main.async {
            self.showMessage(
                """
                Video Capture Complete
                
                Saved to \(self.video_capture.settings.output_file_url!.path)
                """
            )
            
            self.cancelButton.title = "Close"
        }
    }
    
    func captureDidFail(_: VideoCapture) {
        DispatchQueue.main.async {
            self.showMessage(
                """
                Video Capture Failed
                
                Error \(self.video_capture.error!)
                """
            )
            
            self.cancelButton.title = "Close"
        }
    }
    
    func captureDidCancel(_: VideoCapture) {
        DispatchQueue.main.async {
            self.showMessage(
                """
            Video Capture Cancelled
            """
            )
            
            self.cancelButton.title = "Close"
        }
    }
}
