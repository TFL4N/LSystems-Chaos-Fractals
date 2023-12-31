//
//  PickoverAttractor.swift
//  L-Systems
//
//  Created by Spizzace on 5/23/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation

class PickoverAttractor: Attractor {
    init() {
        let params = [
            Parameter(name: "iterations", value: Value(type: .integer, value: 0)),
            Parameter(name: "skip iterations", value: Value(type: .integer, value: 0)),
            Parameter(name: "A", value: Value(type: .float, value: 0)),
            Parameter(name: "B", value: Value(type: .float, value: 0)),
            Parameter(name: "C", value: Value(type: .float, value: 0)),
            Parameter(name: "D", value: Value(type: .float, value: 0))
        ]
        
        super.init(parameters: params, coloringInfo: ColoringInfo())!
    }
    
    override init?(parameters: [Parameter], coloringInfo: ColoringInfo) {
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
        super.init(parameters: parameters, coloringInfo: coloringInfo)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let decoded = Attractor.decodeObject(coder: aDecoder) else {
            return nil
        }
        
        self.init(parameters: decoded.parameters, coloringInfo: decoded.coloringInfo)
    }
    
    override func buildOperationData(atFrame: FrameId = 0, bufferPool: BigBufferPool) -> AttractorOperation {
        let attractor_copy = self.deepCopy()
        return PickoverAttractorOperation(attractor_copy,
                                  frameId: atFrame,
                                  bufferPool: bufferPool)
    }
}

class PickoverAttractorOperation: AttractorOperation {
    override func main() {
        guard !self.isCancelled else {
            return
        }
        
        self.did_start_handler?()
        
        // iterations
        let max_iters = self.attractor.parameter(withName: "iterations")!.value!.integerValue!
        let skip_iters = self.attractor.parameter(withName: "skip iterations")!.value!.integerValue!
        
        // vertex array
        let vertex_count_buffer_limit = BigBufferPool.max_float_vertices_per_buffer
        var current_vertices = [Float]()
        current_vertices.reserveCapacity(vertex_count_buffer_limit * 3)
        
        var current_mus = [Float]()
        current_mus.reserveCapacity(vertex_count_buffer_limit)
        
        // output buffer
        var output_buffers = [AttractorBuffer]()
        var current_vertex_index = 0
        
        let updateOutputBuffer = {
            let vertex_buffer = self.buffer_pool.getBuffer()
            let mu_buffer = self.buffer_pool.getBuffer()
            
            vertex_buffer.setData(current_vertices)
            vertex_buffer.count = current_vertex_index
            
            mu_buffer.setData(current_mus)
            mu_buffer.count = current_vertex_index
            
            let attractor_buffer = AttractorBuffer(vertices: vertex_buffer, mus: mu_buffer)
            output_buffers.append(attractor_buffer)
            
            current_vertices = []
            current_mus = []
            
            current_vertex_index = 0
        }
        
        let releaseBuffers = {
            for buff in output_buffers {
                buff.release()
            }
        }
        
        // seeds
        let A = self.attractor.parameter(withName: "A")!.value(atFrame: self.frame_id)!.floatValue!
        let B = self.attractor.parameter(withName: "B")!.value(atFrame: self.frame_id)!.floatValue!
        let C = self.attractor.parameter(withName: "C")!.value(atFrame: self.frame_id)!.floatValue!
        let D = self.attractor.parameter(withName: "D")!.value(atFrame: self.frame_id)!.floatValue!
        
//        print("A: \(A), B: \(B), C: \(C), D: \(D)")
        
        var x: Float = 0
        var y: Float = 0
        var z: Float = 0
        
        
        // produce data
        var iteration = 0
        while iteration < max_iters {
            guard !self.isCancelled else {
                releaseBuffers()
                return
            }
            
            iteration += 1
            let mu = Float(iteration) / Float(max_iters)
            
            // generate vertex
            let new_x: Float = sin(A*y) + z*cos(B*x)
            let new_y: Float = z*sin(C*x) - cos(D*y)
            let new_z: Float = sin(x)
            
            x = new_x
            y = new_y
            z = new_z
            
            if iteration > skip_iters {
//                print("\(mu) ** \([x, y, z])")
                
                // vertex
                current_vertices.append(contentsOf: [
                    x, y, z
                    ])
                
                // mu
                current_mus.append(mu)
            }
            
            // update vertex index
            current_vertex_index += 1
            if current_vertex_index == vertex_count_buffer_limit {
                updateOutputBuffer()
            }
            
            // update progress
            self.progress = mu
        } // while
        
        if !current_vertices.isEmpty {
            updateOutputBuffer()
        }
        
        guard !self.isCancelled else {
            releaseBuffers()
            return
        }
        
        self.data_buffers = output_buffers
    }
}
