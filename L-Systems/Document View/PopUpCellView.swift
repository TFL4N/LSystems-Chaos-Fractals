//
//  PopUpCellView.swift
//  L-Systems
//
//  Created by Spizzace on 5/6/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class PopUpCellView: NSTableCellView {

    var popUpButton: NSPopUpButton!
    var handler: ((PopUpCellView,Int,String)->())?
    
    public init() {
        super.init(frame: NSRect.zero)
        
        self.popUpButton = NSPopUpButton(frame: NSRect.zero, pullsDown: false)
        self.popUpButton.tag = 1
        self.popUpButton.translatesAutoresizingMaskIntoConstraints = false
        self.popUpButton.target = self
        self.popUpButton.action = #selector(handleSelectedItem(sender:))
        
        self.addSubview(self.popUpButton)
        
        let views: [String:Any] = ["main": self.popUpButton]
        let metrics: [String:NSNumber] = ["marg": Style.TableCellMargin_Height]
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-marg-[main(100)]-marg-|", options: .alignAllCenterY, metrics: metrics, views: views))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-marg-[main]-marg-|", options: [], metrics: metrics, views: views))
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    @objc private func handleSelectedItem(sender: AnyObject) {
        if let menuItem = sender as? NSMenuItem, let h = self.handler {
            h(self, self.popUpButton.itemTitles.index(of: menuItem.title)!, menuItem.title)
        }
    }
}
