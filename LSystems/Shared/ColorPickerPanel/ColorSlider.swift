//
//  ColorSlider.swift
//  L-Systems
//
//  Created by Spizzace on 6/2/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class ColorSlider: NSControl {
    private var indicator_layer: CALayer! = nil
    private var background_layer: CAGradientLayer! = nil
    
    @objc dynamic var value: Float = 0.0 {
        didSet {
            let normalized = self.normalize(value: self.value, min: self.minValue, max: self.maxValue)
            
            let position = self.denormalize(position: CGPoint(x: CGFloat(normalized), y: 0.5), inRect: self.canvasFrame)
            
            self.indicator_layer.position = position
        }
    }
    
    var minValue: Float = 0.0
    var maxValue: Float = 1.0
    
    var gradientColors: (CGColor, CGColor) = (CGColor.white, CGColor.black) {
        didSet {
            self.background_layer.colors = [
                self.gradientColors.0,
                self.gradientColors.1,
            ]
        }
    }
    
    private var canvasFrame: CGRect {
        return self.bounds
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.layer = CALayer()
        self.wantsLayer = true
        
        self.background_layer = self.buildBackgroundLayer()
        self.indicator_layer = self.buildIndicatorLayer()
        
        self.layer?.addSublayer(self.background_layer)
        self.layer?.addSublayer(self.indicator_layer)
        
        self.background_layer.constraints = [
            CAConstraint(attribute: .height, relativeTo: "superlayer", attribute: .height, offset: 0.0),
            CAConstraint(attribute: .width, relativeTo: "superlayer", attribute: .width, offset: 0.0),
            CAConstraint(attribute: .midX, relativeTo: "superlayer", attribute: .midX),
            CAConstraint(attribute: .midY, relativeTo: "superlayer", attribute: .midY)
        ]
        
        self.layer?.layoutManager = CAConstraintLayoutManager()
    }
    
    private func buildBackgroundLayer() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [
            self.gradientColors.0,
            self.gradientColors.1,
        ]
        layer.locations = [0.0, 1.0]
        
        layer.borderColor = CGColor(gray: 0.75, alpha: 1.0)
        layer.borderWidth = 2.0
        layer.cornerRadius = 20.0
        
        layer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
        
        return layer
    }
    
    private func buildIndicatorLayer() -> CALayer {
        let size: CGFloat = 40.0
        
        let new_layer = CALayer()
        new_layer.bounds = CGRect(origin: CGPoint.zero,
                                  size: CGSize(width: size, height: size))
        new_layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        new_layer.borderColor = CGColor(gray: 0.75, alpha: 1.0)
        new_layer.borderWidth = 1.5
        new_layer.cornerRadius = size / 2
        
        new_layer.shadowColor = CGColor.black
        new_layer.shadowOffset = CGSize(width: 0.0, height: 1.5)
        new_layer.shadowOpacity = 0.25
        new_layer.shadowRadius = 1.5
        
        new_layer.backgroundColor = CGColor.white
        
        return new_layer
    }
    
    private func normalize<T: FloatingPoint>(value: T, min: T, max: T ) -> T {
        return (value - min) / (max - min)
    }
    
    private func normalized(position: CGPoint, inRect: CGRect) -> CGPoint {
        var x = (position.x - inRect.minX) / inRect.width
        var y = (position.y - inRect.minY) / inRect.height
        
        x = max(0.0, min(x, 1.0))
        y = max(0.0, min(y, 1.0))
        
        return CGPoint(x: x, y: y)
    }
    
    private func denormalize(position: CGPoint, inRect: CGRect) -> CGPoint {
        return CGPoint(x: inRect.minX + (position.x * inRect.width),
                       y: inRect.minY + (position.y * inRect.height))
    }
    
    override func mouseDown(with event: NSEvent) {
        self.handleMouseEvent(event, animated: true)
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.handleMouseEvent(event, animated: false)
    }
    
    private func handleMouseEvent(_ event: NSEvent, animated: Bool) {
        let position = self.convert(event.locationInWindow, from: nil)
        let normalized = self.normalized(position: position, inRect: self.canvasFrame)
        
        if animated {
            self.indicator_layer.actions = nil
        } else {
            self.indicator_layer.actions = [
                "position": NSNull()
            ]
        }
        
        self.value = Float(normalized.x)
        
        self.indicator_layer.actions = nil
    }
}
