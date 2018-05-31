//
//  BufferPool.swift
//  L-Systems
//
//  Created by Spizzace on 5/30/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation
import Metal

class BufferItem {
    let buffer: MTLBuffer
    var count: Int = 0
    
    init(buffer: MTLBuffer) {
        self.buffer = buffer
    }
    
    func setData(_ data: [Float]) {
        self.buffer.contents()
            .copyMemory(from: data,
                        byteCount: data.count * MemoryLayout<Float>.stride)
    }
}

class BufferPool {
    typealias BufferArray = [BufferItem]
    
    static let max_buffer_length = 512*1024*1024
    static var max_float_vertices_per_buffer = BufferPool.max_buffer_length / (MemoryLayout<Float>.stride * 4)
    let device: MTLDevice
    
    private var clean_buffers = BufferArray()
    private var dirty_buffers = BufferArray()
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    private func createBuffer() -> BufferItem {
        let buffer = device.makeBuffer(length: BufferPool.max_buffer_length, options: [])!
        
        return BufferItem(buffer: buffer)
    }
    
    func runCleanBuffersOperation<Result>(_ block: (inout BufferArray)->Result) -> Result {
        objc_sync_enter(self.clean_buffers)
        defer {
            objc_sync_exit(self.clean_buffers)
        }
        
        return block(&self.clean_buffers)
    }
    
    func runDirtyBuffersOperation<Result>(_ block: (inout BufferArray)->Result) -> Result {
        objc_sync_enter(self.dirty_buffers)
        defer {
            objc_sync_exit(self.dirty_buffers)
        }
        
        return block(&self.dirty_buffers)
    }
    
    func getBuffer() -> BufferItem {
        let buffer = self.runCleanBuffersOperation { (buffers) -> BufferItem? in
            if buffers.isEmpty {
                return nil
            } else {
                return buffers.removeLast()
            }
        } ?? self.createBuffer()
        
        self.runDirtyBuffersOperation { (buffers) -> Void in
            buffers.append(buffer)
        }
        
        return buffer
    }
    
    func releaseBuffer(_ buffer: BufferItem) {
        buffer.count = 0
        
        self.runCleanBuffersOperation { (buffers) -> Void in
            buffers.append(buffer)
        }
    }
}
