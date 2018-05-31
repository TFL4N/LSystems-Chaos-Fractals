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
    
    var current_frame: FrameId = 0

    private var current_buffers_store: [BufferTuple]?
    var current_buffers: [BufferTuple]? {
        get {
            objc_sync_enter(self)
            defer {
                objc_sync_exit(self)
            }
            
            return self.current_buffers_store
        }
        
        set {
            objc_sync_enter(self)
            defer {
                objc_sync_exit(self)
            }
            
            self.current_buffers_store = newValue
        }
    }
    
    init(attractor: Attractor) {
        self.attractor = attractor
    }
    
    
    func buildAttractorVertexDataAtCurrentFrame(bufferPool: BufferPool) {
        self.buildAttractorVertexData(atFrame: self.current_frame, bufferPool: bufferPool)
    }
    
    func buildAttractorVertexData(atFrame: FrameId, bufferPool: BufferPool) {
        self.current_buffers = self.attractor.buildVertexData(atFrame: atFrame, bufferPool: bufferPool)
    }
}
