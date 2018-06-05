//
//  CGUtils.swift
//  L-Systems
//
//  Created by Spizzace on 6/2/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation
import Cocoa

extension CGColor {
    func fromLABtoMTLColor() -> [Float] {
        let comps = self.components!.map {Float($0)}
        return [
            InterpolateUtils.normalize(value: comps[0], min: 0.0, max: 100.0),
            InterpolateUtils.normalize(value: comps[1], min: 0.0, max: 127.0),
            InterpolateUtils.normalize(value: comps[2], min: -128.0, max: 127.0),
            comps[3]
        ]
    }
    
    static var whiteLabColor: CGColor {
        return CGColor.white.converted(to: CGColorSpace(name: CGColorSpace.genericLab)!,
                               intent: .absoluteColorimetric,
                               options: nil)!
    }
}

extension MTLClearColor {
    init(_ colors: [Float]) {
        let colors = colors.map { Double($0) }
        self.init(red: colors[0], green: colors[1], blue: colors[2], alpha: colors[3])
    }
}

extension NumberFormatter {
    static func buildFloatFormatter(min: Float?, max: Float?) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.alwaysShowsDecimalSeparator = true
        formatter.isLenient = true
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 5
        formatter.numberStyle = .decimal
        formatter.maximum = max != nil ? NSNumber(value: max!) : nil
        formatter.minimum = min != nil ? NSNumber(value: min!) : nil
        
        return formatter
    }
    
    static func buildPercentFormatter(fractionDigits: Int = 0) -> NumberFormatter {
        let percentFormatter = NumberFormatter()
        percentFormatter.allowsFloats = true
        percentFormatter.maximumFractionDigits = fractionDigits
        percentFormatter.numberStyle = .percent
        
        return percentFormatter
    }
}

class NSObjectUtils {
    static func observedValueDidChange<T: Equatable>(_ change: [NSKeyValueChangeKey : Any]) -> (Bool, T?) {
        let new_change = change[NSKeyValueChangeKey.newKey] as? T
        let old_change = change[NSKeyValueChangeKey.oldKey] as? T
        
        if let new = new_change,
            let old = old_change {
            if new != old {
                return (true, new)
            } else {
                return (false, new)
            }
        } else {
            return (false, nil)
        }
    }
    
}

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
