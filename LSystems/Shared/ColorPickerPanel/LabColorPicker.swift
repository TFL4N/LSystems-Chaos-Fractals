//
//  LabColorPicker.swift
//  L-Systems
//
//  Created by Spizzace on 6/2/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class LabColorPicker: NSColorPicker, NSColorPickingCustom {
    var view: NSView!
    
    func supportsMode(_ mode: NSColorPanel.Mode) -> Bool {
        return true
    }
    
    func currentMode() -> NSColorPanel.Mode {
        return .none
    }
    
    func provideNewView(_ initialRequest: Bool) -> NSView {
        if initialRequest {
            var top_level_objects: NSArray?
            if Bundle.main.loadNibNamed(NSNib.Name("LabColorPickerView.xib"), owner: self, topLevelObjects: &top_level_objects) {
                self.view = top_level_objects?.first(where: { $0 is NSView }) as? NSView
            }
            
            guard self.view != nil else {
                fatalError("Failed to load LabColorPicker nib")
            }
        }
        
        return self.view
    }
    
    func setColor(_ newColor: NSColor) {
        
    }
}
