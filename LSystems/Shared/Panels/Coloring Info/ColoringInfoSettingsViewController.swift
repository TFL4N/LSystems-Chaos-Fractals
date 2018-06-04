//
//  ColoringInfoViewController.swift
//  L-Systems
//
//  Created by Spizzace on 6/3/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

protocol ColoringInfoSettingsProtocol {
    var coloring_info: ColoringInfo { get }
}

class ColoringInfoSettingsViewController: AttractorDocumentViewController, ColoringInfoSettingsProtocol {

    @IBOutlet var coloring_mode_button: NSPopUpButton!
    let coloring_mode_controller = NSArrayController(content: ColoringType.allStringTypes)
    
    var mode_settings_tab_controller: ColoringInfoSettingsTabController {
        return self.childViewControllers[0] as! ColoringInfoSettingsTabController
    }
    
    @objc dynamic var coloring_mode_raw: ColoringType.RawValue {
        get {
            return self.coloring_info.coloringType.rawValue
        }
        
        set {
            self.coloring_info.coloringType = ColoringType(rawValue: newValue)!
        }
    }
    
    var coloring_info: ColoringInfo {
        return self.attractor_manager.attractor.coloring_info
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    private var needsBindings = true
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if self.needsBindings {
            self.coloring_mode_button
                .bind(.content,
                      to: self.coloring_mode_controller,
                      withKeyPath: "arrangedObjects",
                      options: nil)
            self.coloring_mode_button
                .bind(.selectedObject,
                      to: self,
                      withKeyPath: "coloring_mode_raw",
                      options: nil)
        }
    }
    
    @IBAction func handleColoringModeSelection(_ sender: AnyObject) {
        switch self.coloring_info.coloringType {
        case .None:
            break
        case .Gradient:
            self.mode_settings_tab_controller.selectedTabViewItemIndex = 0
        case .ColorMap:
            self.mode_settings_tab_controller.selectedTabViewItemIndex = 1
        }
    }
}
