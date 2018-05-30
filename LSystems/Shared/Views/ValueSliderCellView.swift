//
//  ValueSliderCellView.swift
//  L-Systems
//
//  Created by Spizzace on 5/27/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class ValueSliderCellView: NSTableCellView {

    var mainTextField: NSTextField!
    var valueSlider: ValueSlider!
    
    var value: Value? {
        willSet {
            self.mainTextField.unbind(.value)
        }
        
        didSet {
            self.valueSlider.value = self.value
            
            self.mainTextField.formatter = self.value?.createNumberFormatter()
            
            if let new_val = self.value {
                self.mainTextField.bind(.value,
                                        to: new_val,
                                        withKeyPath: "numberValue",
                                        options: nil)

            } else {
                self.mainTextField.stringValue = ""
            }
        }
    }
    
    public init() {
        super.init(frame: NSRect.zero)
        
        self.mainTextField = NSTextField(frame: NSRect.zero)
        self.mainTextField.translatesAutoresizingMaskIntoConstraints = false
        
        self.valueSlider = ValueSlider(frame: NSRect.zero)
        self.valueSlider.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(self.mainTextField)
        self.addSubview(self.valueSlider)
        
        let views: [String:Any] = [
            "text" : self.mainTextField,
            "slider" : self.valueSlider
        ]
        let metrics : [String:NSNumber] = [
            "marg" : Style.TableCellMargin_Height
        ]
        
        self.addConstraints(NSLayoutConstraint
            .constraints(withVisualFormat: "H:|-marg-[text(100)]-[slider(100)]-marg-|",
                         options: .alignAllCenterY,
                         metrics: metrics,
                         views: views))
        
        self.addConstraints(NSLayoutConstraint
            .constraints(withVisualFormat: "V:|-marg-[text]-marg-|",
                         options: [],
                         metrics: metrics,
                         views: views))
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
