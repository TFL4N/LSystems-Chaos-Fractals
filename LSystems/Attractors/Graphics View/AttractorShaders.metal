//
//  AttractorShaders.metal
//  L-Systems
//
//  Created by Spizzace on 5/24/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "AttractorShaderTypes.h"

using namespace metal;

typedef struct
{
    float3 position [[attribute(A_VertexAttributePosition)]];
    float4 color [[attribute(A_VertexAttributeColor)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float point_size [[point_size]];
    float4 color;
} ColorInOut;

vertex ColorInOut attractorVertexShader(Vertex in [[stage_in]],
                                        constant A_Uniforms & uniforms [[ buffer(A_BufferIndexUniforms) ]],
                                        constant float* point_size [[ buffer(A_BufferIndexPointSize) ]])
{
    ColorInOut out;
    
    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.color = in.color;
    out.point_size = *point_size;
    
    return out;
}

fragment float4 attractorFragmentShader(ColorInOut in [[stage_in]],
                               constant A_Uniforms & uniforms [[ buffer(A_BufferIndexUniforms) ]])
{
//    float4 color = float4(0.4751, 0.3946, 1.0, 1.0);
    float4 color = in.color;
    
    return color;
}


