//
//  Interpolation.swift
//  L-Systems
//
//  Created by Spizzace on 6/4/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation

class InterpolateUtils {
    static func interpolate<T: BinaryFloatingPoint>(mu: T, from: T, to: T) -> T {
        var val = (to - from) * mu
        val += from
        
        return val
    }
}
