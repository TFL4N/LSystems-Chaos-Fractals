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
    float mu [[attribute(A_VertexAttributeMu)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float point_size [[point_size]];
    float4 color;
    float mu;
} ColorInOut;

void getColors( float mu, constant A_ColorItem* color_items,  int  count, thread A_ColorItem* output) {
    A_ColorItem first = color_items[0];
    A_ColorItem last = color_items[count-1];
    
    output[0] = first;
    output[1] = last;
    
    if( mu == 0.0 ) {
        // return [first, first]
        output[1] = first;
    } else if( mu == 1.0 ) {
        // return [last, last]
        output[0] = last;
    } else {
        for(int i=0; i<count; i++) {
            A_ColorItem item = color_items[i];
            if( item.position > mu ) {
                output[0] = color_items[i-1];
                output[1] = item;
                break;
            }
        }
    }
}

vertex ColorInOut attractorVertexShader(Vertex in [[stage_in]],
                                        constant A_Uniforms & uniforms [[buffer(A_BufferIndexUniforms)]],
                                        constant float* point_size [[buffer(A_BufferIndexPointSize)]],
                                        constant int* coloring_mode [[buffer(A_BufferIndexColorMode)]],
                                        constant float4* base_color [[buffer(A_BufferIndexBaseColor)]],
                                        constant A_ColorItem* main_colors [[buffer(A_BufferIndexMainColors)]],
                                        constant int* main_colors_count [[buffer(A_BufferIndexMainColorsCount)]])
{
    ColorInOut out;
    
    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.point_size = *point_size;
    out.mu = in.mu;
    
    if(*coloring_mode == A_ColoringModeMainColor
       && *main_colors_count != 0) {
        // main coloring
        A_ColorItem colors[2];
        getColors(in.mu, main_colors, *main_colors_count, colors);
        
        A_ColorItem from_color = colors[0];
        A_ColorItem to_color = colors[1];
        
        float local_mu;
        if( from_color.position == to_color.position ) {
            local_mu = 1.0;
        } else {
            local_mu = (in.mu - from_color.position) / (to_color.position - from_color.position);
        }
        
        out.color = mix(from_color.color, to_color.color, float4(in.mu));
    } else {
        // defaults
        out.color = *base_color;
    }
    
    return out;
}

fragment float4 attractorFragmentShader(ColorInOut in [[stage_in]],
                               constant A_Uniforms & uniforms [[ buffer(A_BufferIndexUniforms) ]])
{
//    float4 color = float4(1.0, 60.0, 1.0, 1.0);
    float4 color = in.color;
    
    return color;
}


