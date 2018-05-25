//
//  ImageInfoPanelViewController.swift
//  L-Systems
//
//  Created by Spizzace on 5/25/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class ImageInfoPanelViewController: NSViewController {

    @IBOutlet var saveImageButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func handleSaveImagePress(_ sender: Any?) {
        Notifications.postSaveImagePress(info: nil)
    }
}
