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
        print("wtf1")
        self.createNewDocument(ofType: "LSystem")
    }
    
    @IBAction func newAttractorDocument(sender: Any?) {
        print("wtf2")
        self.createNewDocument(ofType: "Attractor")
    }
    
    @IBAction func newFractalDocument(sender: Any?) {
        print("wtf3")
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
        
        print("new doc: \(type)")
        print("doc class: \(new_doc)")
        doc_cntlr.addDocument(new_doc)
        new_doc.makeWindowControllers()
        print("new doc created")
    }
}

