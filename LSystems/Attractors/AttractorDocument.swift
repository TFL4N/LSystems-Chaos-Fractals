//
//  Document.swift
//  StrangeAttractors
//
//  Created by Spizzace on 5/23/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

enum RenderMode: String {
    case live = "Live"
    case `static` = "Static"
    case video_capture = "Video Capture"
}

enum CameraViewingMode: String {
    case free_floating = "Free Floating"
    case fixed_towards_origin = "Fixed Towards Origin"
}

enum CameraProjectionMode: String {
    case perspective = "Perspective"
    case orthogonal = "Orthogonal"
}

class AttractorDocument: NSDocument, VideoCaptureViewControllerDelegate {

    var attractor_manager: AttractorManager = AttractorManager(attractor: PickoverAttractor())
    var video_capture_settings: VideoCaptureSettings = VideoCaptureSettings()
    
    weak var graphics_window_ctlr: NSWindowController!
    var graphics_view_cltr: AttractorGraphicsViewController! {
        return self.graphics_window_ctlr.contentViewController as? AttractorGraphicsViewController
    }
    
    weak var info_panel_window_ctlr: NSWindowController!
    weak var coloring_info_panel_window_ctlr: NSWindowController!
    
    weak var video_capture_window_ctlr: NSWindowController!
    
    // MARK: - Lifecycle
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    // MARK: - Window Controllers
    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Attractor Document Window Controller")) as! NSWindowController
        self.addWindowController(windowController)
    }
    
    func showGraphicsWindowController() {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        
        // create new graphics window
        if self.graphics_window_ctlr == nil {
            self.graphics_window_ctlr = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Graphics Window Controller")) as! NSWindowController
            self.graphics_window_ctlr.shouldCloseDocument = false
            
            self.addWindowController(self.graphics_window_ctlr)
        }
        
        // create info panel window
        if self.info_panel_window_ctlr == nil {
            self.info_panel_window_ctlr = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Info Panel Window")) as! NSWindowController
            self.info_panel_window_ctlr.shouldCloseDocument = false
            
            self.addWindowController(self.info_panel_window_ctlr)
        }
        
        self.info_panel_window_ctlr.showWindow(self)
        self.graphics_window_ctlr.showWindow(self)
    }
    
    func showColoringInfo() {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        
        if self.coloring_info_panel_window_ctlr == nil {
            self.coloring_info_panel_window_ctlr = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Coloring Info Panel")) as! NSWindowController
            self.coloring_info_panel_window_ctlr.shouldCloseDocument = false
            
            self.addWindowController(self.coloring_info_panel_window_ctlr)
        }
        
        self.coloring_info_panel_window_ctlr.showWindow(self)
    }
    
    // MARK: Video Capture
    func captureVideo() {
        // validate video settings
        if let validation_errors = self.video_capture_settings.validate() {
            let alert = NSAlert()
            alert.messageText = validation_errors.description
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .critical
            
            alert.runModal()
            return
        }
        
        // check if capture in progress
        guard self.video_capture_window_ctlr == nil else {
            let alert = NSAlert()
            alert.messageText = "Video capture already in Progress"
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .critical
            
            alert.runModal()
            return
        }
        
        // build video capture contlr
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        self.video_capture_window_ctlr = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Video Capture Window")) as! NSWindowController
    
        let video_capture_vc = self.video_capture_window_ctlr.contentViewController as! VideoCaptureViewController
        video_capture_vc.delegate = self
        video_capture_vc.video_capture = VideoCapture(attractor: self.attractor_manager.attractor, settings: self.video_capture_settings)
        
        self.addWindowController(self.video_capture_window_ctlr)
        
        self.video_capture_window_ctlr.showWindow(self)
    }
    
    func handleClosePress(_: VideoCaptureViewController) {
        self.removeWindowController(self.video_capture_window_ctlr)
        self.video_capture_window_ctlr.close()
        self.video_capture_window_ctlr = nil
    }
    
    // MARK: File IO
    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        
        let dict: [String: Any] = [
            "attractor": self.attractor_manager.attractor,
            "video_capture_settings": self.video_capture_settings
        ]
        
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.outputFormat = .xml
        
        archiver.encode(dict, forKey: "root")
        archiver.finishEncoding()
        
        return data as Data
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        
        let dict = NSKeyedUnarchiver.unarchiveObject(with: data) as! [String: Any]
        let attractor = dict["attractor"] as! Attractor
        self.attractor_manager = AttractorManager(attractor: attractor)
        
        self.video_capture_settings = dict["video_capture_settings"] as? VideoCaptureSettings ?? VideoCaptureSettings()
    }

    //
    //
    //
    // temp
    //
    //
    //
    func adjustAttractor(_ obj: Attractor) {
        var param = obj.parameter(withName: "D")!
        param.animation = AnimationSequence(keyFrames: [
            KeyFrame(value: Value(type: .float, value: 1.7), duration: 500),
            KeyFrame(value: Value(type: .float, value: 2.0), duration: 200),
            KeyFrame(value: Value(type: .float, value: 1.9), duration: 100)
            ])
        
        param = obj.parameter(withName: "B")!
        param.animation = AnimationSequence(keyFrames: [
            KeyFrame(value: Value(type: .float, value: 1.0), duration: 700),
            KeyFrame(value: Value(type: .float, value: 1.0), duration: 200),
            KeyFrame(value: Value(type: .float, value: 1.6), duration: 100)
            ])
    }
}

