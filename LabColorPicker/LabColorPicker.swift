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
    
    @IBOutlet var l_color_slider: LColorSlider!
    @IBOutlet var a_color_slider: AColorSlider!
    @IBOutlet var b_color_slider: BColorSlider!
    
    @IBOutlet var l_color_textfield: NSTextField!
    @IBOutlet var a_color_textfield: NSTextField!
    @IBOutlet var b_color_textfield: NSTextField!
    
    func supportsMode(_ mode: NSColorPanel.Mode) -> Bool {
        return true
    }
    
    func currentMode() -> NSColorPanel.Mode {
        return .none
    }
    
    func provideNewView(_ initialRequest: Bool) -> NSView {
//        if initialRequest {
        var top_level_objects: NSArray?
        let bundle = Bundle(identifier: "spaice.maine.LabColorPicker")!
        if bundle.loadNibNamed(NSNib.Name("LabColorPickerView"), owner: self, topLevelObjects: &top_level_objects) {
            self.view = top_level_objects?.first(where: { $0 is NSView }) as? NSView
            
            let buildNumberFormatter = { (min: Float, max: Float) -> NumberFormatter in
                let formatter = NumberFormatter()
                formatter.allowsFloats = true
                formatter.generatesDecimalNumbers = true
                formatter.alwaysShowsDecimalSeparator = true
                formatter.minimumFractionDigits = 1
                formatter.maximumFractionDigits = 5
                formatter.numberStyle = .decimal
                formatter.maximum = NSNumber(value: max)
                formatter.minimum = NSNumber(value: min)
                
                return formatter
            }
            
            self.l_color_textfield.formatter = buildNumberFormatter(self.l_color_slider.minValue, self.l_color_slider.maxValue)
            self.a_color_textfield.formatter = buildNumberFormatter(self.a_color_slider.minValue, self.a_color_slider.maxValue)
            self.b_color_textfield.formatter = buildNumberFormatter(self.b_color_slider.minValue, self.b_color_slider.maxValue)
            
            self.l_color_textfield.bind(.value, to: self.l_color_slider, withKeyPath: "value", options: nil)
            self.a_color_textfield.bind(.value, to: self.a_color_slider, withKeyPath: "value", options: nil)
            self.b_color_textfield.bind(.value, to: self.b_color_slider, withKeyPath: "value", options: nil)
            
            self.l_color_slider.addObserver(self, forKeyPath: "value", options: [.new], context: nil)
            self.a_color_slider.addObserver(self, forKeyPath: "value", options: [.new], context: nil)
            self.b_color_slider.addObserver(self, forKeyPath: "value", options: [.new], context: nil)
        }
        
        guard self.view != nil else {
            fatalError("Failed to load LabColorPicker nib")
        }
//        }
        
        return self.view
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
     
        guard let obj = object as? LABColorSlider else {
            return
        }
        
        let color = self.getColor()
        if self.l_color_slider == obj {
            self.a_color_slider.setLabColor(color)
            self.b_color_slider.setLabColor(color)
        } else if self.a_color_slider == obj {
            self.l_color_slider.setLabColor(color)
            self.b_color_slider.setLabColor(color)
        } else if self.b_color_slider == obj {
            self.l_color_slider.setLabColor(color)
            self.a_color_slider.setLabColor(color)
        }
        
        self.colorPanel.color = NSColor(cgColor: color)!
    }
    
    func getColor() -> CGColor {
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        return CGColor(colorSpace: color_space, components: [
            CGFloat(self.l_color_slider.value),
            CGFloat(self.a_color_slider.value),
            CGFloat(self.b_color_slider.value),
                1.0
            ])!
    }
    
    func setColor(_ newColor: NSColor) {
        let lab_color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        let lab_color = newColor.cgColor.converted(to: lab_color_space, intent: .absoluteColorimetric, options: nil)
        
        if let lab_color = lab_color {
            self.l_color_slider.setLabColor(lab_color)
            self.a_color_slider.setLabColor(lab_color)
            self.b_color_slider.setLabColor(lab_color)
        }
    }
}
