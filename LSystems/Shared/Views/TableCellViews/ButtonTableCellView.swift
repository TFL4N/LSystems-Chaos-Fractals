//
//  ButtonTableCellView.swift
//  L-Systems
//
//  Created by Spizzace on 6/10/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class ButtonTableCellView: NSTableCellView {

    var button: NSButton!
    var handler: ((ButtonTableCellView)->())?
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: NSRect.zero)
        self.commonInit()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.button = NSButton(frame: NSRect.zero)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.bezelStyle = .roundRect
        self.button.target = self
        self.button.action = #selector(handleButtonPress(_:))
        
        self.addSubview(self.button)
        
        let views: [String:Any] = [
            "button" : self.button
        ]
        
        let metrics : [String:NSNumber] = [
            "marg" : Style.TableCellMargin_Height
        ]
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-marg-[button]-marg-|", options: [], metrics: metrics, views: views))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-marg-[button]-marg-|", options: [], metrics: metrics, views: views))
    }
    
    @objc func handleButtonPress(_: Any?) {
        self.handler?(self)
    }
}
