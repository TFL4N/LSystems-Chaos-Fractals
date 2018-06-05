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
//    float4 color [[attribute(A_VertexAttributeColor)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float point_size [[point_size]];
    float4 color;
} ColorInOut;

vertex ColorInOut attractorVertexShader(Vertex in [[stage_in]],
                                        constant A_Uniforms & uniforms [[ buffer(A_BufferIndexUniforms) ]],
                                        constant float* point_size [[ buffer(A_BufferIndexPointSize) ]],
                                        constant int* coloring_mode [[ buffer(A_BufferIndexColorMode) ]],
                                        constant float4* base_color [[ buffer(A_BufferIndexBaseColor) ]],
                                        constant A_ColorItem* main_colors [[ buffer(A_BufferIndexMainColors) ]],
                                        constant int* main_colors_count [[ buffer(A_BufferIndexMainColorsCount) ]])
{
    ColorInOut out;
    
    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.point_size = *point_size;
    
    out.color = float4(1.0, 60.0, 1.0, 1.0);
    
    return out;
}

fragment float4 attractorFragmentShader(ColorInOut in [[stage_in]],
                               constant A_Uniforms & uniforms [[ buffer(A_BufferIndexUniforms) ]])
{
    float4 color = float4(1.0, 60.0, 1.0, 1.0);
//    float4 color = in.color;
    
    return color;
}


