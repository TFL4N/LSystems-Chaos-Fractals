//
//  AttractorManager.swift
//  L-Systems
//
//  Created by Spizzace on 5/24/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation

class AttractorManager: NSObject {
    let attractor: Attractor
    
    var current_frame: FrameId = 0

    private var current_buffers_lock = ReadWriteLock()
    private var current_buffers_store: [AttractorBuffer]?
    var current_buffers: [AttractorBuffer]? {
        get {
            self.current_buffers_lock.readLock()
            defer {
                self.current_buffers_lock.unlock()
            }
            
            return self.current_buffers_store
        }
        
        set {
            self.current_buffers_lock.writeLock()
            defer {
                self.current_buffers_lock.unlock()
            }
            
            if let buffers = self.current_buffers_store {
                for buf in buffers {
                    buf.release()
                }
            }
            
            self.current_buffers_store = newValue
        }
    }
    
    init(attractor: Attractor) {
        self.attractor = attractor
        super.init()
        
        self.attractor.addObserver(self, forKeyPath: "didChange", options: [.new, .old], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "didChange" {
            let new_val = (change![NSKeyValueChangeKey.newKey]! as! NSNumber).boolValue
            let old_val = (change![NSKeyValueChangeKey.oldKey] as? NSNumber)?.boolValue
            
            var did_change = new_val
            if let old_val = old_val {
                if old_val != new_val && new_val {
                    did_change = true
                }
            }
            
            if did_change {
                self.handleAttractorDidChange()
            }
        }
    }
    
    private func handleAttractorDidChange() {
        
    }
    
    func buildAttractorVertexDataAtCurrentFrame(bufferPool: BufferPool) {
        self.buildAttractorVertexData(atFrame: self.current_frame, bufferPool: bufferPool)
    }
    
    func buildAttractorVertexData(atFrame: FrameId, bufferPool: BufferPool, force: Bool = false) {
//        if self.attractor.didChange || force {
        self.current_buffers = self.attractor.buildVertexData(atFrame: atFrame, bufferPool: bufferPool)
        self.attractor.didChange = false
//        } else {
//            return self.current_buffers
//        }
    }
}
