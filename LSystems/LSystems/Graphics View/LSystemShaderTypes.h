//
//  ShaderTypes.h
//  L-Systems
//
//  Created by Spizzace on 3/28/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef LSystemShaderTypes_h
#define LSystemShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef NS_ENUM(NSInteger, L_BufferIndex)
{
    L_BufferIndexVertexPositions = 0,
    L_BufferIndexVertexColors    = 1,
    L_BufferIndexTexCoord        = 2,
    
    L_BufferIndexUniforms        = 3,
    
    L_BufferIndexColorMode       = 4
};

typedef NS_ENUM(NSInteger, L_VertexAttribute)
{
    L_VertexAttributePosition  = 0,
    L_VertexAttributeColor     = 1,
    L_VertexAttributeTexCoord  = 2
};

typedef NS_ENUM(NSInteger, L_TextureIndex)
{
    L_TextureIndexColor    = 0,
};

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
} L_Uniforms;

#endif /* ShaderTypes_h */

