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
    
    override func buildOperationData(atFrame: FrameId = 0, bufferPool: BufferPool) -> AttractorOperation {
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
        let vertex_count_buffer_limit = BufferPool.max_float_vertices_per_buffer
        var current_vertices = [Float]()
        current_vertices.reserveCapacity(vertex_count_buffer_limit * 3)
        
        var current_main_colors = [Float]()
        current_main_colors.reserveCapacity(vertex_count_buffer_limit * 4)
        
        // color array
        var coloring_interpolator: GradientColor.Interpolator? = nil
        var coloring_mode = self.attractor.coloring_info.coloringType
        
        if coloring_mode == .Gradient {
            if let color = self.attractor.coloring_info.gradientColor,
                let interpolator = GradientColor
                    .Interpolator(color: color,
                                  interpolatingColorSpace: CGColorSpace(name: CGColorSpace.genericLab)!,
                                  outputColorSpace: CGColorSpace(name: CGColorSpace.genericRGBLinear)!) {
                coloring_interpolator = interpolator
            } else {
                coloring_mode = .None
            }
        }
        
        
        
        // output buffer
        var output_buffers = [AttractorBuffer]()
        var current_vertex_index = 0
        
        let updateOutputBuffer = {
            let vertex_buffer = self.buffer_pool.getBuffer()
            let main_color_buffer = self.buffer_pool.getBuffer()
            
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
            
            // generate main color
            
            if iteration > skip_iters {
                // vertex
                current_vertices.append(contentsOf: [
                    x, y, z
                    ])
                
                // main color
                switch coloring_mode {
                case .Gradient:
                    current_main_colors.append(contentsOf: coloring_interpolator!.interpolate(mu: mu))
                case .ColorMap, .None:
                    let rgb_color = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
                    current_main_colors.append(contentsOf: rgb_color.components!.map {Float($0)})
                }

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
