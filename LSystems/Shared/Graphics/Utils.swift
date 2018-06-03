//
//  CGUtils.swift
//  L-Systems
//
//  Created by Spizzace on 6/2/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation
import Cocoa

class ViewUtils {
    static func constraintsEqualSizeAndPosition(toLayer: String) -> [CAConstraint] {
        return [
            CAConstraint(attribute: .height, relativeTo: toLayer, attribute: .height),
            CAConstraint(attribute: .width, relativeTo: toLayer, attribute: .width),
            CAConstraint(attribute: .midX, relativeTo: toLayer, attribute: .midX),
            CAConstraint(attribute: .midY, relativeTo: toLayer, attribute: .midY)
        ]
    }
}

class CGUtils {
    static func createCheckeredColor(size: Int, darkColor: CGColor, lightColor: CGColor) -> CGColor {
        let image = createCheckeredImage(size: size, darkColor: darkColor, lightColor: lightColor)
        let pattern = createPattern(fromImage: image)
        
        return createColor(fromPattern: pattern)
    }
    
    static func createCheckeredImage(size: Int, darkColor: CGColor, lightColor: CGColor) -> CGImage {
        let rgb_color_space = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil,
                                width: size * 2,
                                height: size * 2,
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * size * 2,
                                space: rgb_color_space,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)!
        
        let square_size = CGSize(width: size, height: size)
        
        context.setFillColor(darkColor)
        context.fill(CGRect(origin: CGPoint(x: 0, y: 0), size: square_size))
        context.fill(CGRect(origin: CGPoint(x: size, y: size), size: square_size))
        
        context.setFillColor(lightColor)
        context.fill(CGRect(origin: CGPoint(x: size, y: 0), size: square_size))
        context.fill(CGRect(origin: CGPoint(x: 0, y: size), size: square_size))
        
        return context.makeImage()!
    }
    
    static func createPattern(fromImage image: CGImage) -> CGPattern {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        
        var callbacks = CGPatternCallbacks(version: 0, drawPattern: { (info, context) in
            let image = Unmanaged<CGImage>.fromOpaque(info!).takeUnretainedValue()
            context.draw(image, in: CGRect(origin: CGPoint.zero,
                                           size: CGSize(width: image.width,
                                                        height: image.height)))
            
        }, releaseInfo: { info in
            Unmanaged<CGImage>.fromOpaque(info!).release()
        })
        
        let unsafeImage = Unmanaged.passRetained(image).toOpaque()
        return CGPattern(info: unsafeImage,
                         bounds: CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height)),
                         matrix: CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0),
                         xStep: width,
                         yStep: height,
                         tiling: CGPatternTiling.constantSpacing,
                         isColored: true,
                         callbacks: &callbacks)!
    }
    
    static func createColor(fromPattern pattern: CGPattern) -> CGColor {
        let color_space = CGColorSpace(patternBaseSpace: nil)!
        let comps: [CGFloat] = [1.0]
        return CGColor(patternSpace: color_space, pattern: pattern, components: comps)!
    }
}

protocol CFTypeProtocol {
    static var typeID: CFTypeID { get }
}

extension CFTypeProtocol {
    
    static func conditionallyCast<T>(_ value: T) -> Self? {
        
        guard CFGetTypeID(value as CFTypeRef) == typeID else {
            return nil
        }
        
        return (value as! Self)
    }
}

extension CGColor : CFTypeProtocol {}
