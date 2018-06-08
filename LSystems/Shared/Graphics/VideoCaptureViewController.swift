//
//  VideoCaptureViewController.swift
//  L-Systems
//
//  Created by Spizzace on 6/8/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class VideoCaptureViewController: NSViewController {

    static private(set) var sharedWindow: NSWindowController = {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        
        return storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Video Capture Window")) as! NSWindowController
    }()
    
    static var shared: VideoCaptureViewController {
        return self.sharedWindow.contentViewController as! VideoCaptureViewController
    }
    
    @IBOutlet var progressView: ProgressView!
    

}
