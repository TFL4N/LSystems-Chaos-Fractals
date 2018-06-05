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
        return from + (to - from) * mu
    }
    
    static func normalize<T: BinaryFloatingPoint>(value: T, min: T, max: T) -> T {
        return (value - min) / (max - min)
    }
}
