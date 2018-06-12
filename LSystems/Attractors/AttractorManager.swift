//
//  AttractorManager.swift
//  L-Systems
//
//  Created by Spizzace on 5/24/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation

class AttractorManager: NSObject {
    typealias Buffers = (frame: FrameId, buffers: [AttractorBuffer])
    
    let attractor: Attractor
    lazy var operation_queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Attractor Factory Queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        
        return queue
    }()
    
    @objc dynamic var current_frame: FrameId = 0
    private var requesting_refresh: Bool = false

    private var current_buffers_lock = ReadWriteLock()
    private var current_buffers_store: Buffers?
    var current_buffers: Buffers? {
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
            
            if let buffer = self.current_buffers_store {
                for buf in buffer.buffers {
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
    
    deinit {
        self.attractor.removeObserver(self, forKeyPath: "didChange", context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "didChange" {
            if let change = change {
                let foo: (Bool, Bool?) = NSObjectUtils.observedValueDidChange(change)
                if foo.0 && foo.1! {
                    self.handleAttractorDidChange()
                }
            }
        }
    }
    
    private func handleAttractorDidChange() {
//        print("Handle Did Change")
    }
    
    func requestRefresh() {
        self.requesting_refresh = true
    }
    
    func buildAttractorVertexDataAtCurrentFrame(bufferPool: BigBufferPool, progressHandler: AttractorOperation.ProgressHandler? = nil, didStartHandler: AttractorOperation.DidStartHandler? = nil, didFinishHandler: ((Bool)->())? = nil,  sync: Bool = false) {
        self.buildAttractorVertexData(atFrame: self.current_frame, bufferPool: bufferPool, progressHandler: progressHandler, didStartHandler: didStartHandler, didFinishHandler: didFinishHandler, sync: sync)
    }
    
    func buildAttractorVertexData(atFrame: FrameId, bufferPool: BigBufferPool, progressHandler: AttractorOperation.ProgressHandler? = nil, didStartHandler: AttractorOperation.DidStartHandler? = nil, didFinishHandler: ((Bool)->())? = nil, sync: Bool = false) {
        var buffers_outdated = false
        let current_operation = self.operation_queue.operations.first as? AttractorOperation
        if let buf = self.current_buffers {
            let op_bool = current_operation == nil || current_operation!.frame_id != self.current_frame
            buffers_outdated = buf.frame != self.current_frame && op_bool
        }
        
        if self.attractor.didChange
            || self.requesting_refresh
            || buffers_outdated {
            self.attractor.didChange = false
            self.requesting_refresh = false
            
            let frame_id = self.current_frame
            let operation = self.attractor.buildOperationData(atFrame: atFrame, bufferPool: bufferPool)
            operation.did_start_handler = didStartHandler
            operation.progress_handler = progressHandler
            operation.completionBlock = {
                if let buffers = operation.data_buffers {
                    self.current_buffers = Buffers(frame_id, buffers)
                }
                
                didFinishHandler?(operation.isCancelled)
            }
            
            if sync {
                operation.start()
            } else {
                self.operation_queue.cancelAllOperations()
                self.operation_queue.addOperation(operation)
            }
        }
    }
    
    func getMTLBaseColorAtCurrentFrame() -> vector_float4 {
        return self.getMTLBaseColor(atFrame: self.current_frame)
    }
    
    func getMTLBaseColor(atFrame: FrameId) -> vector_float4 {
        return vector_float4(1.0)
    }
   
    func getMainColorsAtCurrentFrame() -> [A_ColorItem]? {
        return self.getMainColors(atFrame: self.current_frame)
    }
    
    func getMainColors(atFrame: FrameId) -> [A_ColorItem]? {
        return self.attractor.coloring_info.gradientColor?.getMTLGradientColorItems()
    }
}
