//
//  ColorLinearCellView.swift
//  L-Systems
//
//  Created by Spizzace on 6/2/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class GradientColorItemCellView: NSTableCellView {

    var positionTextField: NSTextField!
    var colorWell: ColorWell!
    
    var gradient_color_item: GradientColorItem? = nil {
        willSet {
            self.positionTextField.unbind(.value)
        }
        
        didSet {
            if let item = self.gradient_color_item {
                self.positionTextField.bind(.value,
                                        to: item,
                                        withKeyPath: "position",
                                        options: nil)
                self.colorWell.color = item.color
                
            } else {
                self.positionTextField.stringValue = ""
                self.colorWell.color = CGColor.white
            }
        }
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        // find views
        for sbv in self.subviews {
            if let tf = sbv as? NSTextField {
                self.positionTextField = tf
            } else if let well = sbv as? ColorWell {
                self.colorWell = well
            }
        }
        
        // config
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        formatter.minimum = 0
        formatter.maximum = 1
        
        self.positionTextField.formatter = formatter
        
        // observation
        self.colorWell.didSelectColor = { (color) in
            self.gradient_color_item?.color = color
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("ColorWell Did Change")
        self.gradient_color_item?.color = self.colorWell.color
    }
}
