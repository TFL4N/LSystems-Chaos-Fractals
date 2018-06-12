//
//  TextFieldCellView.swift
//  L-Systems
//
//  Created by Spizzace on 5/6/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class TextFieldCellView: NSTableCellView, NSTextFieldDelegate {
    
    var mainTextField: NSTextField!
    var handler: ((TextFieldCellView)->())?
    
    public init() {
        super.init(frame: NSRect.zero)
        self.commonInit()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.mainTextField = NSTextField(frame: NSRect.zero)
        self.mainTextField.translatesAutoresizingMaskIntoConstraints = false
        self.mainTextField.tag = 1
        self.mainTextField.delegate = self
        
        
        self.addSubview(self.mainTextField)
        
        let views: [String:Any] = ["main": self.mainTextField]
        let metrics: [String:NSNumber] = ["marg": Style.TableCellMargin_Height]
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-marg-[main(100)]-marg-|", options: .alignAllCenterY, metrics: metrics, views: views))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-marg-[main]-marg-|", options: [], metrics: metrics, views: views))
    }
    
    // MARK: NSTextField Delegate
    override func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            switch textField.tag {
            case self.mainTextField.tag:
                handler?(self)
            default:
                break
            }
        }
    }
}
