//
//  Benchmark.swift
//  Utilities
//
//  Created by Spizzace on 3/14/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation

public class Benchmark {
    public let initialTime: CFAbsoluteTime
    public private(set) var startTime: CFAbsoluteTime
    
    public var elapsedTime: CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent() - self.startTime
    }
    
    public var totalElapsedTime: CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent() - self.initialTime
    }
    
    public init() {
        self.initialTime = CFAbsoluteTimeGetCurrent()
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
    
    public func reset() {
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
    
    public func printList(_ vars: Any..., includeTotal: Bool = false) {
        for n in vars {
            print(n, terminator: " : ")
        }
        
        if includeTotal {
            print(self.elapsedTime, " : ", self.totalElapsedTime)
        } else {
            print(self.elapsedTime)
        }
    }
}
