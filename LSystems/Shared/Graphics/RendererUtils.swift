//
//  RendererUtils.swift
//  L-Systems
//
//  Created by Spizzace on 5/25/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Metal

enum RendererUtilsError: Error {
    case FailedToMallocBytes
}

extension MTLTexture {
    func bytes() throws -> UnsafeMutableRawPointer {
        let width = self.width
        let height   = self.height
        let rowBytes = self.width * 4
        
        guard let ptr = malloc(width * height * 4) else {
            throw RendererUtilsError.FailedToMallocBytes
        }
        self.getBytes(ptr,
                      bytesPerRow: rowBytes,
                      from: MTLRegionMake2D(0, 0, width, height),
                      mipmapLevel: 0)
        
        return ptr
    }
    
    func toImage() -> CGImage? {
        let bytes_ptr: UnsafeMutableRawPointer
        do {
            bytes_ptr = try bytes()
        } catch {
            print(error)
            return nil
        }
        
        let pColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
        
        let selftureSize = self.width * self.height * 4
        let rowBytes = self.width * 4
        
        let provider = CGDataProvider(dataInfo: nil, data: bytes_ptr, size: selftureSize) { (_, _, _) in
            
        }!
        let cgImageRef = CGImage(width: self.width,
                                 height: self.height,
                                 bitsPerComponent: 8,
                                 bitsPerPixel: 32,
                                 bytesPerRow: rowBytes,
                                 space: pColorSpace,
                                 bitmapInfo: bitmapInfo,
                                 provider: provider,
                                 decode: nil,
                                 shouldInterpolate: true,
                                 intent: CGColorRenderingIntent.defaultIntent)!
        
        return cgImageRef
    }
}
