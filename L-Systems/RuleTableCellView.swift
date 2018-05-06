//
//  RuleView.swift
//  L-Systems
//
//  Created by Spizzace on 3/28/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class RuleTableCellView: NSTableCellView, NSTextFieldDelegate {

    var lhsTextField: NSTextField!
    var rhsTextField: NSTextField!
    public var rule: Rule? {
        didSet {
            self.lhsTextField.stringValue = self.rule?.variable ?? ""
            self.rhsTextField.stringValue = self.rule?.value ?? ""
        }
    }
    
    public init() {
        super.init(frame: NSRect.zero)
        self.lhsTextField = NSTextField()
        self.lhsTextField.tag = 1
        self.lhsTextField.delegate = self
        self.lhsTextField.translatesAutoresizingMaskIntoConstraints = false
        
        self.rhsTextField = NSTextField()
        self.rhsTextField.tag = 2
        self.rhsTextField.delegate = self
        self.rhsTextField.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(self.lhsTextField)
        self.addSubview(self.rhsTextField)
        
        let views: [String:Any] = ["lhs": self.lhsTextField,
                     "rhs": self.rhsTextField]
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[lhs(100)]-[rhs]-|", options: .alignAllCenterY, metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[lhs]-|", options: [], metrics: nil, views: views))
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    // MARK: NSTextField Delegate
    override func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            switch textField.tag {
            case self.lhsTextField.tag:
                self.rule?.variable = self.lhsTextField.stringValue
            case self.rhsTextField.tag:
                self.rule?.value = self.rhsTextField.stringValue
            default:
                break
            }
        }
    }
}
