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

class AttractorDocument: NSDocument {

    var attractor_manager: AttractorManager! = AttractorManager(attractor: PickoverAttractor())
    
    weak var graphics_window_ctlr: NSWindowController!
    var graphics_view_cltr: AttractorGraphicsViewController! {
        return self.graphics_window_ctlr.contentViewController as? AttractorGraphicsViewController
    }
    
    weak var info_panel_window_ctlr: NSWindowController!
    weak var coloring_info_panel_window_ctlr: NSWindowController!
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return true
    }

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
    
    // MARK: File IO
    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        
        let dict: [String: Any] = [
            "attractor": self.attractor_manager.attractor
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
    }

    //
    //
    //
    // temp
    //
    //
    //
    func adjustAttractor(_ obj: inout Attractor) {
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

