//
//  ColoringInfoSettingsTabController.swift
//  L-Systems
//
//  Created by Spizzace on 6/3/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class ColoringInfoSettingsTabController: NSTabViewController, ColoringInfoSettingsProtocol {

    var coloring_info: ColoringInfo {
        return (self.parent as! ColoringInfoSettingsProtocol).coloring_info
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
