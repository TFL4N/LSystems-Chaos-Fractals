//
//  AttractorManager.swift
//  L-Systems
//
//  Created by Spizzace on 5/24/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation

class AttractorManager {
    let attractor: Attractor
    var vertex_data: [Float]? = nil
    
    var current_frame: FrameId = 0

    init(attractor: Attractor) {
        self.attractor = attractor
    }
    
    func buildAttractorVertexData() {
        self.vertex_data = self.attractor.buildVertexArray()
    }
    
    func buildAttractorVertexDataAtCurrentFrame() {
        self.buildAttractorVertexData(atFrame: self.current_frame)
    }
    
    func buildAttractorVertexData(atFrame: FrameId) {
        self.vertex_data = self.attractor.buildVertexArray(atFrame: atFrame)
    }
}
