//
//  PickoverAttractor.swift
//  L-Systems
//
//  Created by Spizzace on 5/23/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation


class PickoverAttractor: Attractor {
    override init() {
        let params = [
            Parameter(name: "iterations", value: Value(type: .integer, value: 0)),
            Parameter(name: "skip iterations", value: Value(type: .integer, value: 0)),
            Parameter(name: "A", value: Value(type: .float, value: 0)),
            Parameter(name: "B", value: Value(type: .float, value: 0)),
            Parameter(name: "C", value: Value(type: .float, value: 0)),
            Parameter(name: "D", value: Value(type: .float, value: 0))
        ]
        
        super.init(parameters: params)!
    }
    
    override init?(parameters: [Parameter]) {
        // check parameters
        for p in ["A","B","C","D"] {
            if !parameters.contains(where: { (par: Parameter) -> Bool in
                return par.name == p
                    && par.value != nil
                    && par.value!.type == .float
            }) {
                return nil
            }
        }
        
        // init
        super.init(parameters: parameters)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let coder = aDecoder as! NSKeyedUnarchiver
        guard let params = coder.decodeObject(forKey: "attractor_parameters") as? [Parameter]
            else { return nil }
        
        self.init(parameters: params)
    }
    
    override func buildVertexArray(atFrame: FrameId) -> [Float] {
        // iterations
        let max_iters = self.parameter(withName: "iterations")!.value!.integerValue!
        let skip_iters = self.parameter(withName: "skip iterations")!.value!.integerValue!
        
        // vertex array
        var output = [Float]()
        output.reserveCapacity((max_iters-skip_iters)*3)
        
        // seeds
        let A = self.parameter(withName: "A")!.value(atFrame: atFrame)!.floatValue!
        let B = self.parameter(withName: "B")!.value(atFrame: atFrame)!.floatValue!
        let C = self.parameter(withName: "C")!.value(atFrame: atFrame)!.floatValue!
        let D = self.parameter(withName: "D")!.value(atFrame: atFrame)!.floatValue!
        
//        print("iters: \(max_iters)")
//        print("A: \(A), B: \(B), C: \(C), D: \(D)")
        
        var x: Float = 0
        var y: Float = 0
        var z: Float = 0
        
        // produce data
        var iteration = 0
        while iteration < max_iters {
            iteration += 1
            
            let new_x: Float = sin(A*y) + z*cos(B*x)
            let new_y: Float = z*sin(C*x) - cos(D*y)
            let new_z: Float = sin(x)
            
            x = new_x
            y = new_y
            z = new_z
            
            if iteration > skip_iters {
                output.append(x)
                output.append(y)
                output.append(z)
            }
        }
        
        return output
    }
}
