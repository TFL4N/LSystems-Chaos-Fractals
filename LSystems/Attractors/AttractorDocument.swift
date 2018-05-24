//
//  Document.swift
//  StrangeAttractors
//
//  Created by Spizzace on 5/23/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class AttractorDocument: NSDocument {

    var attractor: Attractor = Attractor()
    
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

    // MARK: File IO
    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        
        let dict: [String: Any] = [
            "attractor": self.attractor
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
        self.attractor = dict["attractor"] as! Attractor
    }


}

