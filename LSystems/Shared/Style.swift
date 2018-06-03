//
//  Style.swift
//  L-Systems
//
//  Created by Spizzace on 5/6/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class Style {
    static let TableCellMargin_Height: NSNumber = 10.0
    
    static func createDefaultCheckerColor() -> CGColor {
        return CGUtils.createCheckeredColor(size: 2,
                                            darkColor: CGColor(gray: 0.75, alpha: 1.0),
                                            lightColor: CGColor(gray: 0.0, alpha: 1.0))
    }
}
