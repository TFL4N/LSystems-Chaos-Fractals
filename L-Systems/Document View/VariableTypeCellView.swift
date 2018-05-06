//
//  VariableTypeCellView.swift
//  L-Systems
//
//  Created by Spizzace on 5/6/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class VariableTypeCellView: PopUpCellView {
    
    var variable: Variable? {
        didSet {
            self.popUpButton.selectItem(withTitle: self.variable?.type.rawValue ?? VariableType.Draw.rawValue)
        }
    }
    
    override init() {
        super.init()
        
        self.popUpButton.title = ""
        self.popUpButton.addItems(withTitles: VariableType.allTypeStrings)
        
        self.handler = { (_, _, title) in
            if let v = self.variable {
                v.type = VariableType(rawValue: title)!
                Notifications.postVariableTypeDidChange(v)
            }
        }
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
}
