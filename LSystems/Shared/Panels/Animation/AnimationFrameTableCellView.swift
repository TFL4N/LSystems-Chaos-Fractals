//
//  AnimationKeyFrameTableCellView.swift
//  L-Systems
//
//  Created by Spizzace on 6/10/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class AnimationKeyFrameTableCellView: NSTableCellView {

    @IBOutlet var valueTextField: NSTextField!
    @IBOutlet var durationTextField: NSTextField!
    
    var keyframe: KeyFrame? {
        willSet {
            self.valueTextField.unbind(.value)
            self.durationTextField.unbind(.value)
        }
        
        didSet {
            if let frame = self.keyframe {
                self.valueTextField.formatter = frame.value.createNumberFormatter()
                self.durationTextField.formatter = NumberFormatter.buildIntegerFormatter(min: 0, max: nil)
                
                self.valueTextField.bind(.value,
                                         to: frame.value,
                                         withKeyPath: "numberValue",
                                         options: nil)
                self.durationTextField.bind(.value,
                                         to: frame,
                                         withKeyPath: "duration",
                                         options: nil)
                
            } else {
                self.valueTextField.formatter = nil
                self.durationTextField.formatter = nil
                
                self.valueTextField.stringValue = ""
                self.durationTextField.stringValue = ""
            }
        }
    }
}
