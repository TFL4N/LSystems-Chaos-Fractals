//
//  ColorSlider.swift
//  L-Systems
//
//  Created by Spizzace on 6/2/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class LABColorSlider: NSControl {
    private var indicator_layer: CALayer! = nil
    private var background_layer: CAGradientLayer! = nil
    
    @objc dynamic var value: Float = 0.0 {
        willSet {
            self.willChangeValue(for: \.value)
        }
        
        didSet {
            self.didChangeValue(for: \.value)
            
            let normalized = self.normalize(value: self.value, min: self.minValue, max: self.maxValue)
            
            let position = self.denormalize(position: CGPoint(x: CGFloat(normalized), y: 0.5), inRect: self.canvasFrame)
            
            self.indicator_layer.position = position
            self.refreshIndicator()
        }
    }
    
    var minValue: Float = 0.0
    var maxValue: Float = 1.0
    
    fileprivate var current_l: CGFloat = 0.0
    fileprivate var current_a: CGFloat = 0.0
    fileprivate var current_b: CGFloat = 0.0
    
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
    
    // MARK: - Lifecycle
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
        
        self.indicator_layer.constraints = [
            CAConstraint(attribute: .midY, relativeTo: "superlayer", attribute: .midY)
        ]
        
        self.layer?.layoutManager = CAConstraintLayoutManager()
    }
    
    // MARK: - Colors
    final func setLabColor(_ color: CGColor) {
        let comps = color.components!
        self.setLabColor(L: comps[0], A: comps[1], B: comps[2], alpha: comps[3])
    }
    
    func setLabColor(L: CGFloat, A: CGFloat, B: CGFloat, alpha: CGFloat = 1.0) {
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        let color = CGColor(colorSpace: color_space, components: [L,A,B,alpha])!
        
        self.gradientColors = (color,color)
    }
    
    fileprivate func refreshIndicator() {
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        self.indicator_layer.backgroundColor = CGColor(colorSpace: color_space, components: [self.current_l, self.current_a, self.current_b, 1.0])
    }
    
    // MARK: - Layers
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
        new_layer.position = CGPoint(x: 0.0, y: 0.5)
        
        new_layer.borderColor = CGColor(gray: 0.75, alpha: 1.0)
        new_layer.borderWidth = 1.5
        new_layer.cornerRadius = size / 2
        
        new_layer.shadowColor = CGColor.black
        new_layer.shadowOffset = CGSize(width: 0.0, height: 1.5)
        new_layer.shadowOpacity = 0.25
        new_layer.shadowRadius = 1.5
        
        new_layer.backgroundColor = CGColor.white
        
        new_layer.actions = [
            "backgroundColor": NSNull()
        ]
        
        return new_layer
    }
    
    // MARK: - Mouse Events
    private func normalize<T: FloatingPoint>(value: T, min: T, max: T ) -> T {
        return (value - min) / (max - min)
    }
    
    private func denormalize<T: FloatingPoint>(value: T, min: T, max: T) -> T {
        return min + (value * (max - min))
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
            self.indicator_layer.actions = ["colors": NSNull()]
        } else {
            self.indicator_layer.actions = [
                "position": NSNull(),
                "colors": NSNull()
            ]
        }
        
        self.value = self.denormalize(value: Float(normalized.x), min: self.minValue, max: self.maxValue)
        
        self.indicator_layer.actions = ["colors": NSNull()]
    }
}

class LColorSlider: LABColorSlider {
    override var current_l: CGFloat {
        get {
            return CGFloat(self.value)
        }
        set {}
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
        self.minValue = 0.0
        self.maxValue = 100.0
    }
    
    override func setLabColor(L: CGFloat, A: CGFloat, B: CGFloat, alpha: CGFloat = 1.0) {
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        let min_color = CGColor(colorSpace: color_space, components: [CGFloat(self.minValue),A,B,alpha])!
        let max_color = CGColor(colorSpace: color_space, components: [CGFloat(self.maxValue),A,B,alpha])!
        
        self.current_a = A
        self.current_b = B
        
        self.gradientColors = (min_color,max_color)
        self.refreshIndicator()
    }
}

class AColorSlider: LABColorSlider {
    override var current_a: CGFloat {
        get {
            return CGFloat(self.value)
        }
        set {}
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
        self.minValue = -110.0
        self.maxValue = 110.0
    }
    
    override func setLabColor(L: CGFloat, A: CGFloat, B: CGFloat, alpha: CGFloat = 1.0) {
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        let min_color = CGColor(colorSpace: color_space, components: [L,CGFloat(self.minValue),B,alpha])!
        let max_color = CGColor(colorSpace: color_space, components: [L,CGFloat(self.maxValue),B,alpha])!
        
        self.current_l = L
        self.current_b = B
        
        self.gradientColors = (min_color,max_color)
        self.refreshIndicator()
    }
}

class BColorSlider: LABColorSlider {
    override var current_b: CGFloat {
        get {
            return CGFloat(self.value)
        }
        set {}
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
        self.minValue = -110.0
        self.maxValue = 110.0
    }
    
    override func setLabColor(L: CGFloat, A: CGFloat, B: CGFloat, alpha: CGFloat = 1.0) {
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        let min_color = CGColor(colorSpace: color_space, components: [L,A,CGFloat(self.minValue),alpha])!
        let max_color = CGColor(colorSpace: color_space, components: [L,A,CGFloat(self.maxValue),alpha])!
        
        self.current_l = L
        self.current_a = A
        
        self.gradientColors = (min_color,max_color)
        self.refreshIndicator()
    }
}
