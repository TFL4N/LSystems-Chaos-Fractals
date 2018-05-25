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

    init(attractor: Attractor) {
        self.attractor = attractor
    }
    
    func buildAttractorVertexData() {
        self.vertex_data = self.attractor.buildVertexArray()
    }
}
