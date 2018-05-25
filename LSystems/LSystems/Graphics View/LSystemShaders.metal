//
//  Shaders.metal
//  L-Systems
//
//  Created by Spizzace on 3/28/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "LSystemShaderTypes.h"

using namespace metal;

typedef struct
{
    float3 position [[attribute(L_VertexAttributePosition)]];
    float4 color [[attribute(L_VertexAttributeColor)]];
    float2 texCoord [[attribute(L_VertexAttributeTexCoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float4 color;
    float2 texCoord;
} ColorInOut;

vertex ColorInOut lSystemVertexShader(Vertex in [[stage_in]],
                               constant L_Uniforms & uniforms [[ buffer(L_BufferIndexUniforms) ]])
{
    ColorInOut out;

    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.color = in.color;
    out.texCoord = in.texCoord;

    return out;
}

fragment float4 lSystemFragmentShader(ColorInOut in [[stage_in]],
                               constant L_Uniforms & uniforms [[ buffer(L_BufferIndexUniforms) ]],
                               texture2d<half> colorMap     [[ texture(L_TextureIndexColor) ]],
                               constant int* color_mode [[ buffer(L_BufferIndexColorMode) ]])
{
    if( *color_mode <= 0 ) {
        float4 color = float4(float3(0.0), float(1.0));
        return color;
    } else {
        constexpr sampler colorSampler(mip_filter::none,
                                       mag_filter::nearest,
                                       min_filter::nearest);
        
        half4 colorSample   = colorMap.sample(colorSampler, in.texCoord.xy);
        
        return float4(colorSample);
    }
}
