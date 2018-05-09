//
//  Document.swift
//  L-Systems
//
//  Created by Spizzace on 5/6/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class Document: NSDocument {

    var l_system: LSystem = LSystem()
    var color_info: ColorInfo = ColorInfo()
    
    weak var l_system_window_ctlr: NSWindowController!
    weak var graphics_window_ctlr: NSWindowController!
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    // MARK: Window Controllers
    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        self.l_system_window_ctlr = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        
        self.addWindowController(self.l_system_window_ctlr)
    }
    
    func showGraphicsWindowController() {
        // deep copy l system
        let new_l_system = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self.l_system)) as! LSystem
        
        // create new graphics window
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        
        self.graphics_window_ctlr = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Graphics Window Controller")) as! NSWindowController
        
        let graphics_cntlr = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Graphics Controller")) as! LGraphicsViewController
        graphics_cntlr.l_system = new_l_system
        
        self.graphics_window_ctlr.contentViewController = graphics_cntlr
        self.graphics_window_ctlr.shouldCloseDocument = false
        
        self.addWindowController(self.graphics_window_ctlr)
        
        // show window
        self.graphics_window_ctlr.showWindow(self)
    }

    // MARK: File IO
    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        
        let dict: [String: Any] = [
            "l_system": self.l_system,
            "color_info": self.color_info
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
        self.l_system = dict["l_system"] as! LSystem
        self.color_info = dict["color_info"] as! ColorInfo
    }


}

