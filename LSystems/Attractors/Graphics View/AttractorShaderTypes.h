//
//  AttractorShaderTypes.h
//  L-Systems
//
//  Created by Spizzace on 5/24/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

#ifndef AttractorShaderTypes_h
#define AttractorShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef NS_ENUM(NSInteger, A_BufferIndex)
{
    A_BufferIndexVertexPositions = 0,
    A_BufferIndexVertexColors    = 1,
    A_BufferIndexTexCoord        = 2,
    
    A_BufferIndexUniforms        = 3,
    
    A_BufferIndexColorMode       = 4
};

typedef NS_ENUM(NSInteger, A_VertexAttribute)
{
    A_VertexAttributePosition  = 0,
    A_VertexAttributeColor     = 1,
    A_VertexAttributeTexCoord  = 2
};

typedef NS_ENUM(NSInteger, A_TextureIndex)
{
    A_TextureIndexColor    = 0,
};

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
} A_Uniforms;

#endif /* AttractorShaderTypes_h */
