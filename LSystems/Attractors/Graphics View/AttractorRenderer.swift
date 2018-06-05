//
//  AttractorRenderer.swift
//  L-Systems
//
//  Created by Spizzace on 5/23/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Metal
import MetalKit
import simd

protocol AttractorRendererDelegate {
    var attractor_manager: AttractorManager! { get }
    func rendererDidDraw()
    func dataBuildProgress(_: Float)
    func dataBuildDidStart()
    func dataBuildDidFinished(wasCancelled: Bool)
}

class AttractorRenderer: NSObject, MTKViewDelegate {
    // MARK: Class Vars
    // The 256 byte aligned size of our uniform structure
    static let alignedUniformsSize = (MemoryLayout<A_Uniforms>.size & ~0xFF) + 0x100
    static let maxColorBufferSize = 128 * MemoryLayout<A_ColorItem>.stride
    
    static let maxBuffersInFlight = 3
    
    enum RendererError: Error {
        case badVertexDescriptor
    }
    
    // MARK: Instance Vars
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState
    var depthState: MTLDepthStencilState
    
    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    var current_frame_index = 0
    
    var dynamicUniformBuffer: MTLBuffer
    var uniformBufferOffset = 0
    var uniforms: UnsafeMutablePointer<A_Uniforms>

    var buffer_pool: BigBufferPool
    
    var coloring_mode_buffers: [Int]
    var base_color_buffers: [vector_float4]
    let main_color_buffers: [MTLBuffer]
    var main_color_count_buffers: [Int]
    
    
    // Camera View Mode
    var camera_viewing_mode: CameraViewingMode {
        return CameraViewingMode(rawValue: self.camera_viewing_mode_raw)!
    }
    
    @objc dynamic var camera_viewing_mode_raw = CameraViewingMode.fixed_towards_origin.rawValue {
        didSet {
            print("Did Set Viewing Mode: \(self.camera_viewing_mode_raw)")
        }
    }
    
    // Camera Perspective Mode
    var camera_projection_mode: CameraProjectionMode {
        return CameraProjectionMode(rawValue: self.camera_projection_mode_raw)!
    }
    @objc dynamic var camera_projection_mode_raw = CameraProjectionMode.perspective.rawValue {
        didSet {
            
        }
    }
   
    // Free Floating Transformations
    @objc dynamic var rotation: Float = 0
    var rotationAxis: float3 = float3(0.0, 0.0, 1.0)
    @objc dynamic var scale: Float = 2.5
    var translation: (x: Float, y: Float) = (0.0, 0.0)
    
    // projection
    var projectionMatrix: matrix_float4x4 = matrix_float4x4()
    @objc dynamic var pointSize: Float = 1.0
    
    // ETC
    var delegate: AttractorRendererDelegate
    
    // MARK: Lifecycle
    init(metalKitView: MTKView, delegate: AttractorRendererDelegate) throws {
        self.delegate = delegate
        self.device = metalKitView.device!
        self.commandQueue = self.device.makeCommandQueue()!
        
        //
        // Build Buffers
        //
        self.buffer_pool = BigBufferPool(device: self.device)
        
        // Build Uniform Buffer
        let uniformBufferSize = AttractorRenderer.alignedUniformsSize * AttractorRenderer.maxBuffersInFlight
        
        self.dynamicUniformBuffer = self.device.makeBuffer(length:uniformBufferSize,
                                                           options:[MTLResourceOptions.storageModeShared])!
        
        self.dynamicUniformBuffer.label = "UniformBuffer"
        
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents()).bindMemory(to:A_Uniforms.self, capacity:1)
        
        // Build Main Color Buffer
        var mutable_main_color_buffer = [MTLBuffer]()
        
        for _ in 0..<AttractorRenderer.maxBuffersInFlight {
            mutable_main_color_buffer.append(self.device
                .makeBuffer(length: AttractorRenderer.maxColorBufferSize,
                            options: [MTLResourceOptions.storageModeShared])!)
        }
        
        self.main_color_buffers = mutable_main_color_buffer
        
        self.coloring_mode_buffers = [Int](repeating: 1, count: AttractorRenderer.maxColorBufferSize)
        self.base_color_buffers = [vector_float4](repeating: vector_float4(1.0), count: AttractorRenderer.maxBuffersInFlight)
        self.main_color_count_buffers = [Int](repeating: 0, count: AttractorRenderer.maxBuffersInFlight)
        
        //
        // Build Pipeline
        //
        
        // Build Vertex Descriptor
        metalKitView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm
        metalKitView.sampleCount = 1
        
        let mtlVertexDescriptor = AttractorRenderer.buildMetalVertexDescriptor()
        
        do {
            pipelineState = try AttractorRenderer.buildRenderPipelineWithDevice(device: device,
                                                                              metalKitView: metalKitView,
                                                                              mtlVertexDescriptor: mtlVertexDescriptor)
        } catch {
            print("Unable to compile render pipeline state.")
            throw error
        }
        
        // Build State Descriptor
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDesciptor.isDepthWriteEnabled = true
        self.depthState = device.makeDepthStencilState(descriptor:depthStateDesciptor)!
        
        super.init()
    }
    
    class func buildMetalVertexDescriptor() -> MTLVertexDescriptor {
        // Create a Metal vertex descriptor specifying how vertices will by laid out for input into our render
        //   pipeline and how we'll layout our Model IO vertices
        
        let mtlVertexDescriptor = MTLVertexDescriptor()
        
        mtlVertexDescriptor.attributes[A_VertexAttribute.position.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[A_VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[A_VertexAttribute.position.rawValue].bufferIndex = A_BufferIndex.vertexPositions.rawValue
        
//        mtlVertexDescriptor.attributes[A_VertexAttribute.color.rawValue].format = MTLVertexFormat.float4
//        mtlVertexDescriptor.attributes[A_VertexAttribute.color.rawValue].offset = 0
//        mtlVertexDescriptor.attributes[A_VertexAttribute.color.rawValue].bufferIndex = A_BufferIndex.vertexColors.rawValue
        
//        mtlVertexDescriptor.attributes[A_VertexAttribute.texCoord.rawValue].format = MTLVertexFormat.float2
//        mtlVertexDescriptor.attributes[A_VertexAttribute.texCoord.rawValue].offset = 0
//        mtlVertexDescriptor.attributes[A_VertexAttribute.texCoord.rawValue].bufferIndex = A_BufferIndex.texCoord.rawValue
        
        mtlVertexDescriptor.layouts[A_BufferIndex.vertexPositions.rawValue].stride = 12
        mtlVertexDescriptor.layouts[A_BufferIndex.vertexPositions.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[A_BufferIndex.vertexPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
//        mtlVertexDescriptor.layouts[A_BufferIndex.vertexColors.rawValue].stride = 16
//        mtlVertexDescriptor.layouts[A_BufferIndex.vertexColors.rawValue].stepRate = 1
//        mtlVertexDescriptor.layouts[A_BufferIndex.vertexColors.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
//        mtlVertexDescriptor.layouts[A_BufferIndex.texCoord.rawValue].stride = 8
//        mtlVertexDescriptor.layouts[A_BufferIndex.texCoord.rawValue].stepRate = 1
//        mtlVertexDescriptor.layouts[A_BufferIndex.texCoord.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        return mtlVertexDescriptor
    }
    
    class func buildRenderPipelineWithDevice(device: MTLDevice,
                                             metalKitView: MTKView,
                                             mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object
        
        let library = device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "attractorVertexShader")
        let fragmentFunction = library?.makeFunction(name: "attractorFragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.sampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    private func updateState() {
        self.current_frame_index = (self.current_frame_index + 1) % AttractorRenderer.maxBuffersInFlight
        
        self.updateDynamicBufferState()
        self.updateGameState()
        self.updateVertexBuffer()
        self.updateColorBufferState()
    }
    
    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering
        self.uniformBufferOffset = AttractorRenderer.alignedUniformsSize * self.current_frame_index
        
        self.uniforms = UnsafeMutableRawPointer(self.dynamicUniformBuffer.contents() + self.uniformBufferOffset).bindMemory(to:A_Uniforms.self, capacity:1)
    }
    
    private func updateGameState() {
        /// Update any game state before rendering
        
        uniforms[0].projectionMatrix = projectionMatrix
        
        switch self.camera_viewing_mode {
        case .free_floating:
            let rotationMatrix = matrix4x4_rotation(radians: rotation, axis: self.rotationAxis)
            let scaleMatrix = matrix4x4_scaling(self.scale)
            let translationMatrix = matrix4x4_translation(self.translation.x, self.translation.y, 0.0)
            
            let modelMatrix = simd_mul(simd_mul(scaleMatrix, rotationMatrix), translationMatrix)
            let viewMatrix = matrix4x4_translation(0.0, 0.0, -8.0)
            uniforms[0].modelViewMatrix = simd_mul(viewMatrix, modelMatrix)
        case .fixed_towards_origin:
            let scaleMatrix = matrix4x4_scaling(self.scale)
            
            
            let modelMatrix = scaleMatrix * self.fixed_point_rotation
            let viewMatrix = matrix4x4_translation(0.0, 0.0, -8.0)
            uniforms[0].modelViewMatrix = viewMatrix * modelMatrix
        }
    }

    private func updateVertexBuffer() {
        guard let manager = self.delegate.attractor_manager else {
            return
        }
        
        manager.buildAttractorVertexDataAtCurrentFrame(
            bufferPool: self.buffer_pool,
            progressHandler: { (progress) in
                self.delegate.dataBuildProgress(progress)
        },
            didStartHandler: {
                self.delegate.dataBuildDidStart()
        },
            didFinishHandler: { (cancelled) in
                self.delegate.dataBuildDidFinished(wasCancelled: cancelled)
        })
    }
    
    private func updateColorBufferState() {
        guard let manager = self.delegate.attractor_manager else {
            return
        }
        
        // update coloring mode
        self.coloring_mode_buffers[self.current_frame_index] = 1
        
        // update base color
        self.base_color_buffers[self.current_frame_index] = manager.getMTLBaseColorAtCurrentFrame()
        
        // update main colors
        if let main_colors = manager.getMainColorsAtCurrentFrame() {
            let count = main_colors.count
            self.main_color_buffers[self.current_frame_index].contents()
                .copyMemory(from: main_colors,
                            byteCount: count * MemoryLayout<A_ColorItem>.stride)
            self.main_color_count_buffers[self.current_frame_index] = count
        } else {
            self.main_color_count_buffers[self.current_frame_index] = 0
        }
    }
    
    func draw(in view: MTKView) {
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            let semaphore = inFlightSemaphore
            
            /// Update State
            self.updateState()
            
            let data_buffer = self.delegate.attractor_manager.current_buffers ?? []
            for buf in data_buffer {
                buf.retain()
            }
            
            commandBuffer.addCompletedHandler { (_ commandBuffer) in
                self.delegate.rendererDidDraw()
                
                for buf in data_buffer {
                    buf.release()
                }
                
                semaphore.signal()
            }
            
            /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
            ///   holding onto the drawable and blocking the display pipeline any longer than necessary
            if let renderPassDescriptor = view.currentRenderPassDescriptor {
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0)
                
                /// Final pass rendering code here
                if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                    renderEncoder.label = "Primary Render Encoder"
                    
                    renderEncoder.pushDebugGroup("Draw Attractor")
                    
                    for buffers in data_buffer {
                        renderEncoder.setCullMode(.back)
                        renderEncoder.setFrontFacing(.counterClockwise)
                        renderEncoder.setRenderPipelineState(pipelineState)
                        renderEncoder.setDepthStencilState(depthState)
                        
                        // set uniform buffer
                        renderEncoder
                            .setVertexBuffer(dynamicUniformBuffer,
                                             offset:uniformBufferOffset,
                                             index: A_BufferIndex.uniforms.rawValue)
                        renderEncoder
                            .setFragmentBuffer(dynamicUniformBuffer,
                                               offset:uniformBufferOffset,
                                               index: A_BufferIndex.uniforms.rawValue)
                        
                        // set vertex buffer
                        renderEncoder
                            .setVertexBuffer(buffers.buffer,
                                             offset: 0,
                                             index: A_BufferIndex.vertexPositions.rawValue)
                        
                        // set point size
                        renderEncoder
                            .setVertexBytes(&self.pointSize,
                                            length: MemoryLayout<Float>.stride,
                                            index: A_BufferIndex.pointSize.rawValue)
                        
                        // set coloring mode
                        renderEncoder
                            .setVertexBytes(&(self.coloring_mode_buffers[self.current_frame_index]),
                                            length: MemoryLayout<Int>.stride,
                                            index: A_BufferIndex.colorMode.rawValue)
                        
                        // set base color
                        renderEncoder
                            .setVertexBytes(&(self.base_color_buffers[self.current_frame_index]),
                                            length: MemoryLayout<vector_float4>.stride,
                                            index: A_BufferIndex.baseColor.rawValue)
                        
                        // set main colors
                        renderEncoder
                            .setVertexBuffer(self.main_color_buffers[self.current_frame_index],
                                             offset: 0,
                                             index: A_BufferIndex.mainColors.rawValue)
                        
                        // set main colors count
                        renderEncoder
                            .setVertexBytes(&(self.main_color_count_buffers[self.current_frame_index]),
                                            length: MemoryLayout<Int>.stride,
                                            index: A_BufferIndex.mainColorsCount.rawValue)
                        
                        // draw vertices
                        renderEncoder
                            .drawPrimitives(type: .point,
                                            vertexStart: 0,
                                            vertexCount: buffers.count)
                    }
                    
                    // end encoding
                    renderEncoder.popDebugGroup()
                    
                    renderEncoder.endEncoding()
                    
                    if let drawable = view.currentDrawable {
                        commandBuffer.present(drawable)
                    }
                }
            }
            
            commandBuffer.commit()
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here
        let aspect = Float(size.width) / Float(size.height)
        projectionMatrix = matrix_perspective_right_hand(fovyRadians: radians_from_degrees(65), aspectRatio:aspect, nearZ: 0.1, farZ: 100.0)
    }
    
    // MARK: Fixed Point Mode
    var yaw_rotation_axis = float4(0,1,0,1)
    var roll_rotation_axis = float4(0,0,1,1)
    var pitch_rotation_axis = float4(1,0,0,1)
    
    var locked_rotational_axes = false
    
    var fixed_point_rotation = matrix_float4x4(diagonal: vector_float4(1))
    
    func addRotation(yaw: Float = 0, roll: Float = 0, pitch: Float = 0) {
        if yaw != 0 {
            let rotation = matrix4x4_rotation(radians: yaw,
                                              axis: self.yaw_rotation_axis)
            
            self.fixed_point_rotation = rotation * self.fixed_point_rotation
            
            if self.locked_rotational_axes {
                self.roll_rotation_axis = rotation * self.yaw_rotation_axis
                self.pitch_rotation_axis = rotation * self.pitch_rotation_axis
            }
        }
        
        if roll != 0 {
            let rotation = matrix4x4_rotation(radians: roll,
                                              axis: self.roll_rotation_axis)
            
            self.fixed_point_rotation = rotation * self.fixed_point_rotation
            
            if self.locked_rotational_axes {
                self.yaw_rotation_axis = rotation * self.yaw_rotation_axis
                self.pitch_rotation_axis = rotation * self.pitch_rotation_axis
            }
        }
        
        if pitch != 0 {
            let rotation = matrix4x4_rotation(radians: pitch,
                                              axis: self.pitch_rotation_axis)
            
            self.fixed_point_rotation = rotation * self.fixed_point_rotation
            
            if self.locked_rotational_axes {
                self.yaw_rotation_axis = rotation * self.yaw_rotation_axis
                self.roll_rotation_axis = rotation * self.pitch_rotation_axis
            }
        }
    }
    
    // MARK: Helpers
    static func pointSizeFormatter() -> NumberFormatter {
        return NumberFormatter.buildFloatFormatter(min: 0.0, max: 10.0)
    }
    
    func addTranslationWithAdjustment(_ trans: (x: Float, y: Float)) {
        var trans_vector = float4(trans.x, trans.y, 0.0, 0.0)
        let rotation_matrix = matrix4x4_rotation(radians: self.rotation, axis: self.rotationAxis)
        
        trans_vector = simd_mul(trans_vector, rotation_matrix)
        
        self.translation.x += trans_vector.x
        self.translation.y += trans_vector.y
    }
}
