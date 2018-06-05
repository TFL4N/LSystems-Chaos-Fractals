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
    lazy var operation_queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Attractor Factory Queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        
        return queue
    }()
    
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
//        print("Handle Did Change")
    }
    
    func buildAttractorVertexDataAtCurrentFrame(bufferPool: BufferPool, progressHandler: AttractorOperation.ProgressHandler? = nil, didStartHandler: AttractorOperation.DidStartHandler? = nil, didFinishHandler: ((Bool)->())? = nil, force: Bool = false) {
        self.buildAttractorVertexData(atFrame: self.current_frame, bufferPool: bufferPool, progressHandler: progressHandler, didStartHandler: didStartHandler, didFinishHandler: didFinishHandler, force: force)
    }
    
    func buildAttractorVertexData(atFrame: FrameId, bufferPool: BufferPool, progressHandler: AttractorOperation.ProgressHandler? = nil, didStartHandler: AttractorOperation.DidStartHandler? = nil, didFinishHandler: ((Bool)->())? = nil, force: Bool = false) {
        if self.attractor.didChange || force {
            self.attractor.didChange = false
            
            let operation = self.attractor.buildOperationData(atFrame: atFrame, bufferPool: bufferPool)
            operation.did_start_handler = didStartHandler
            operation.progress_handler = progressHandler
            operation.completionBlock = {
                if let buffers = operation.data_buffers {
                    self.current_buffers = buffers
                }
                
                didFinishHandler?(operation.isCancelled)
            }
            
            self.operation_queue.cancelAllOperations()
            self.operation_queue.addOperation(operation)
        }
    }
}
