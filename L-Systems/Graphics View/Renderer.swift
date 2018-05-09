//
//  Renderer.swift
//  L-Systems
//
//  Created by Spizzace on 5/6/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Metal
import MetalKit
import simd

// The 256 byte aligned size of our uniform structure
let alignedUniformsSize = (MemoryLayout<Uniforms>.size & ~0xFF) + 0x100

let maxBuffersInFlight = 3

enum RendererError: Error {
    case badVertexDescriptor
}

class Renderer: NSObject, MTKViewDelegate {
    
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState
    var depthState: MTLDepthStencilState
    
    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)

    var dynamicUniformBuffer: MTLBuffer
    var uniformBufferOffset = 0
    var uniformBufferIndex = 0
    var uniforms: UnsafeMutablePointer<Uniforms>
    
    var vertexBuffer: MTLBuffer
    var vertexCount: Int
    
    var colorBuffer: MTLBuffer
    
    var projectionMatrix: matrix_float4x4 = matrix_float4x4()
    var rotation: Float = 0
    var scale: Float = 1.0
    
    var l_system_manager: LSystemManager
    
    init(metalKitView: MTKView, l_system: LSystem) throws {
        self.l_system_manager = LSystemManager(l_system: l_system)
        self.device = metalKitView.device!
        self.commandQueue = self.device.makeCommandQueue()!
        
        // Build Uniform Buffer
        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight
        
        self.dynamicUniformBuffer = self.device.makeBuffer(length:uniformBufferSize,
                                                           options:[MTLResourceOptions.storageModeShared])!
        
        self.dynamicUniformBuffer.label = "UniformBuffer"
        
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents()).bindMemory(to:Uniforms.self, capacity:1)
        
        // Build Vertex Descriptor
        metalKitView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        metalKitView.sampleCount = 1
        
        let mtlVertexDescriptor = Renderer.buildMetalVertexDescriptor()
        
        do {
            pipelineState = try Renderer.buildRenderPipelineWithDevice(device: device,
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
        
        // Build Vertex Data
        do {
            let vertices = try self.l_system_manager.buildLineVertexBuffer()
            let length = vertices.count * MemoryLayout<Float>.stride
            self.vertexBuffer = self.device.makeBuffer(bytes: vertices, length: length, options: [])!
            self.vertexCount = vertices.count
            
            let colors = Array<Float>(repeating: 0.0, count: self.vertexCount / 3 * 4)
            let color_length = colors.count * MemoryLayout<Float>.stride
            
            self.colorBuffer = self.device.makeBuffer(bytes: colors, length: color_length, options: [])!
        } catch {
            throw error
        }
            
        super.init()
    }
    
    class func buildMetalVertexDescriptor() -> MTLVertexDescriptor {
        // Create a Metal vertex descriptor specifying how vertices will by laid out for input into our render
        //   pipeline and how we'll layout our Model IO vertices
        
        let mtlVertexDescriptor = MTLVertexDescriptor()
        
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].bufferIndex = BufferIndex.vertexPositions.rawValue
        
        mtlVertexDescriptor.attributes[VertexAttribute.color.rawValue].format = MTLVertexFormat.float4
        mtlVertexDescriptor.attributes[VertexAttribute.color.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.color.rawValue].bufferIndex = BufferIndex.vertexColors.rawValue
        
        mtlVertexDescriptor.layouts[BufferIndex.vertexPositions.rawValue].stride = 12
        mtlVertexDescriptor.layouts[BufferIndex.vertexPositions.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.vertexPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        mtlVertexDescriptor.layouts[BufferIndex.vertexColors.rawValue].stride = 16
        mtlVertexDescriptor.layouts[BufferIndex.vertexColors.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.vertexColors.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        return mtlVertexDescriptor
    }
    
    class func buildRenderPipelineWithDevice(device: MTLDevice,
                                             metalKitView: MTKView,
                                             mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object
        
        let library = device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
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
    
    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering
        
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to:Uniforms.self, capacity:1)
    }
    
    private func updateGameState() {
        /// Update any game state before rendering
        
        uniforms[0].projectionMatrix = projectionMatrix
        
        let rotationAxis = float3(1, 1, 0)
        let rotationMatrix = matrix4x4_rotation(radians: rotation, axis: rotationAxis)
        
        let scaleMatrix = matrix4x4_scaling(self.scale)
        
        let modelMatrix = simd_mul(scaleMatrix, rotationMatrix)
        let viewMatrix = matrix4x4_translation(0.0, 0.0, -8.0)
        uniforms[0].modelViewMatrix = simd_mul(viewMatrix, modelMatrix)
//        rotation += 0.01
    }
    
    func draw(in view: MTKView) {
        /// Per frame updates hare
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            let semaphore = inFlightSemaphore
            commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
                semaphore.signal()
            }
            
            self.updateDynamicBufferState()
            
            self.updateGameState()
            
            /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
            ///   holding onto the drawable and blocking the display pipeline any longer than necessary
            let renderPassDescriptor = view.currentRenderPassDescriptor
            
            if let renderPassDescriptor = renderPassDescriptor {
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
                
                /// Final pass rendering code here
                if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                    renderEncoder.label = "Primary Render Encoder"
                    
                    renderEncoder.pushDebugGroup("Draw Box")
                    
                    renderEncoder.setCullMode(.back)
                    renderEncoder.setFrontFacing(.counterClockwise)
                    renderEncoder.setRenderPipelineState(pipelineState)
                    renderEncoder.setDepthStencilState(depthState)
                    
                    // set uniform buffer
                    renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
                    renderEncoder.setFragmentBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
                    
                    // set vertex buffer
                    renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: BufferIndex.vertexPositions.rawValue)
                    renderEncoder.setFragmentBuffer(self.vertexBuffer, offset: 0, index: BufferIndex.vertexPositions.rawValue)
                    
                    // set color buffer
                    renderEncoder.setVertexBuffer(self.colorBuffer, offset: 0, index: BufferIndex.vertexColors.rawValue)
                    renderEncoder.setFragmentBuffer(self.colorBuffer, offset: 0, index: BufferIndex.vertexColors.rawValue)
                    
                    // draw vertices
                    renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: self.vertexCount)
                    
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
}
