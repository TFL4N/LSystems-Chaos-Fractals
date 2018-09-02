//
//  AppDelegate.swift
//  L-Systems
//
//  Created by Spizzace on 5/6/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


    @IBAction func newLSystemDocument(sender: Any?) {
        self.createNewDocument(ofType: "spaice.lsystem")
    }
    
    @IBAction func newAttractorDocument(sender: Any?) {
        self.createNewDocument(ofType: "spaice.attractor")
    }
    
    @IBAction func newFractalDocument(sender: Any?) {
        
    }
    
    private func createNewDocument(ofType type: String) {
        let doc_cntlr = NSDocumentController.shared
        let new_doc: NSDocument
        
        do {
            new_doc = try doc_cntlr.makeUntitledDocument(ofType: type)
        } catch {
            print(error)
            return
        }
        
        doc_cntlr.addDocument(new_doc)
        new_doc.makeWindowControllers()
    }
}

