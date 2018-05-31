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
    
    override func buildVertexData(atFrame: FrameId, bufferPool: BufferPool) -> [AttractorBuffer] {
        // iterations
        let max_iters = self.parameter(withName: "iterations")!.value!.integerValue!
        let skip_iters = self.parameter(withName: "skip iterations")!.value!.integerValue!
        
        // vertex array
        let vertex_count_buffer_limit = BufferPool.max_float_vertices_per_buffer
        var current_vertices = [Float]()
        current_vertices.reserveCapacity(vertex_count_buffer_limit * 3)
        
        var current_main_colors = [Float]()
        current_main_colors.reserveCapacity(vertex_count_buffer_limit * 4)
        
        var output_buffers = [AttractorBuffer]()
        var current_vertex_index = 0
        
        let updateOutputBuffer = {
            let vertex_buffer = bufferPool.getBuffer()
            let main_color_buffer = bufferPool.getBuffer()
            
            vertex_buffer.setData(current_vertices)
            vertex_buffer.count = current_vertex_index
            
            main_color_buffer.setData(current_main_colors)
            main_color_buffer.count = current_vertex_index
            
            let attractor_buffer = AttractorBuffer(vertices: vertex_buffer, main_colors: main_color_buffer)
            output_buffers.append(attractor_buffer)
            
            current_vertices = []
            current_main_colors = []
            
            current_vertex_index = 0
        }
        
        // seeds
        let A = self.parameter(withName: "A")!.value(atFrame: atFrame)!.floatValue!
        let B = self.parameter(withName: "B")!.value(atFrame: atFrame)!.floatValue!
        let C = self.parameter(withName: "C")!.value(atFrame: atFrame)!.floatValue!
        let D = self.parameter(withName: "D")!.value(atFrame: atFrame)!.floatValue!
        
//        print("A: \(A), B: \(B), C: \(C), D: \(D)")
        
        var x: Float = 0
        var y: Float = 0
        var z: Float = 0
        
        // produce data
        var iteration = 0
        while iteration < max_iters {
            iteration += 1
            
            // generate vertex
            let new_x: Float = sin(A*y) + z*cos(B*x)
            let new_y: Float = z*sin(C*x) - cos(D*y)
            let new_z: Float = sin(x)
            
            x = new_x
            y = new_y
            z = new_z
            
            // generate main color
            let main_red: Float = 0.0
            let main_green: Float = 0.0
            let main_blue: Float = 0.0
            let main_alpha: Float = 1.0
            
            if iteration > skip_iters {
                current_vertex_index += 1
                if current_vertex_index <= vertex_count_buffer_limit {
                    // vertex
                    current_vertices.append(contentsOf: [
                        x, y, z
                        ])
                    
                    // bgra
                    current_main_colors.append(contentsOf: [
                        main_blue,
                        main_green,
                        main_red,
                        main_alpha
                        ])
                } else {
                    updateOutputBuffer()
                }
            }
        }
        
        if !current_vertices.isEmpty {
            updateOutputBuffer()
        }
        
        return output_buffers
    }
}
