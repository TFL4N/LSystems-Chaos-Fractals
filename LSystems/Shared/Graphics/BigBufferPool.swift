//
//  BufferPool.swift
//  L-Systems
//
//  Created by Spizzace on 5/30/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation
import Metal

class BigBuffer: Equatable {
    let buffer: MTLBuffer
    var count: Int = 0
    
    unowned let buffer_pool: BigBufferPool
    private(set) var retainCount = 0
    
    init(buffer: MTLBuffer, bufferPool: BigBufferPool) {
        self.buffer = buffer
        self.buffer_pool = bufferPool
    }
    
    static func == (lhs: BigBuffer, rhs: BigBuffer) -> Bool {
        return lhs === rhs
    }
    
    func setData(_ data: [Float]) {
        self.buffer.contents()
            .copyMemory(from: data,
                        byteCount: data.count * MemoryLayout<Float>.stride)
    }
    
    func retain() {
        self.retainCount += 1
    }
    
    func release() {
        self.retainCount -= 1
        
        if self.retainCount <= 0 {
            self.buffer_pool.recycleBuffer(self)
        }
    }
    
    func recycle() {
        self.count = 0
        self.retainCount = 0
    }
}

class BigBufferPool {
    typealias BufferArray = [BigBuffer]
    
    static let max_buffer_length = 512*1024*1024
    static var max_float_vertices_per_buffer = BigBufferPool.max_buffer_length / (MemoryLayout<Float>.stride * 4)
    let device: MTLDevice
    
    private var clean_buffers = BufferArray()
    private var dirty_buffers = BufferArray()
    
    private var clean_buffers_lock = ReadWriteLock()
    private var dirty_buffers_lock = ReadWriteLock()
    
    private var recycler_timer: Timer? = nil
    
    init(device: MTLDevice) {
        self.device = device
        self.recycler_timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(handleRecyclerTimer(_:)), userInfo: nil, repeats: true)
    }
    
    deinit {
        self.recycler_timer?.invalidate()
        self.recycler_timer = nil
    }
    
    private func createBuffer() -> BigBuffer {
        let buffer = device.makeBuffer(length: BigBufferPool.max_buffer_length, options: [])!
        
        return BigBuffer(buffer: buffer, bufferPool: self)
    }
    
    func readCleanBuffersOperation<Result>(_ block: (BufferArray)->Result) -> Result {
        return self.clean_buffers_lock.withReadLock { block(self.clean_buffers) }
    }
    
    func writeCleanBuffersOperation<Result>(_ block: (inout BufferArray)->Result) -> Result {
        return self.clean_buffers_lock.withWriteLock { block(&self.clean_buffers) }
    }
    
    func readDirtyBuffersOperation<Result>(_ block: (BufferArray)->Result) -> Result {
        return self.dirty_buffers_lock.withReadLock { block(self.dirty_buffers) }
    }
    
    func writeDirtyBuffersOperation<Result>(_ block: (inout BufferArray)->Result) -> Result {
        return self.dirty_buffers_lock.withWriteLock { block(&self.dirty_buffers) }
    }
    
    func getBuffer() -> BigBuffer {
        let buffer = self.writeCleanBuffersOperation { (buffers) -> BigBuffer? in
            if buffers.isEmpty {
                return nil
            } else {
                return buffers.removeLast()
            }
        } ?? self.createBuffer()
        
        buffer.retain()
        
        self.writeDirtyBuffersOperation { (buffers) -> Void in
            buffers.append(buffer)
        }
        
        return buffer
    }
    
    func recycleBuffer(_ buffer: BigBuffer) {
        self.writeDirtyBuffersOperation { ( buffers ) in
            if let idx = buffers.index(of: buffer) {
                buffers.remove(at: idx)
                
                buffer.recycle()
                
                self.writeCleanBuffersOperation { (clean_buffers) in
                    clean_buffers.append(buffer)
                }
            }
        }
    }
    
    @objc private func handleRecyclerTimer(_ timer: Timer) {
        self.writeDirtyBuffersOperation { (buffers) in
            var recyclable_buffers = [(Int,BigBuffer)]()
            
            for (i, buf) in buffers.reversed().enumerated() {
                if buf.retainCount <= 0 {
                   recyclable_buffers.append((i, buf))
                }
            }
            
            let count = buffers.count
            for buf in recyclable_buffers {
                buffers.remove(at: count - buf.0 - 1)
                buf.1.recycle()
                
                self.writeCleanBuffersOperation { (clean_buffers) in
                    clean_buffers.append(buf.1)
                }
            }
        }
    }
}
