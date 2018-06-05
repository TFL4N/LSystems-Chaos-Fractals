//
//  ColorSlider.swift
//  L-Systems
//
//  Created by Spizzace on 6/2/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class LABColorSlider: NSControl {
    fileprivate var background_layer: CAGradientLayer! = nil
    
    private var indicator_layer: CALayer! = nil
    private var indicator_bg_layer: CALayer! = nil
    private var indicator_fg_layer: CALayer! = nil
    
    @objc dynamic var value: Float = 0.0 {
        willSet {
            self.willChangeValue(for: \.value)
        }
        
        didSet {
            self.didChangeValue(for: \.value)
            
            let normalized = InterpolateUtils.normalize(value: self.value, min: self.minValue, max: self.maxValue)
            
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
    fileprivate var current_alpha: CGFloat = 1.0
    
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
        
        self.background_layer.colors = [color, color]
    }
    
    fileprivate func refreshIndicator() {
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        self.indicator_fg_layer.backgroundColor = CGColor(colorSpace: color_space, components: [self.current_l, self.current_a, self.current_b, self.current_alpha])
    }
    
    // MARK: - Layers
    fileprivate func buildBackgroundLayer() -> CAGradientLayer {
        let new_layer = CAGradientLayer()
        new_layer.name = "background"
        new_layer.colors = [
            CGColor.white,
            CGColor.black
        ]
        
        new_layer.borderColor = CGColor(gray: 0.75, alpha: 1.0)
        new_layer.borderWidth = 2.0
        new_layer.cornerRadius = 5.0
        
        new_layer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        
        new_layer.actions = [
            "colors" : NSNull()
        ]
        
        return new_layer
    }
    
    fileprivate func buildIndicatorLayer() -> CALayer {
        let size: Int = 40
        let bounds = CGRect(origin: CGPoint.zero,
                            size: CGSize(width: size, height: size))
        let corner_radius = CGFloat(size) / 2
        let pos = CGPoint(x: size/2, y: size/2)
        
        let new_bg_layer = CALayer()
        new_bg_layer.name = "indicator_bg"
        new_bg_layer.bounds = bounds
        new_bg_layer.position = pos
        new_bg_layer.cornerRadius = corner_radius
        
        new_bg_layer.backgroundColor = Style.createDefaultCheckerColor()
        
        self.indicator_bg_layer = new_bg_layer
        
        let new_fg_layer = CALayer()
        new_fg_layer.name = "indicator_fg"
        new_fg_layer.bounds = bounds
        new_fg_layer.position = pos
        
        new_fg_layer.borderColor = CGColor(gray: 0.75, alpha: 1.0)
        new_fg_layer.borderWidth = 1.5
        new_fg_layer.cornerRadius = corner_radius
        
        new_fg_layer.backgroundColor = CGColor.white
        
        new_fg_layer.actions = [
            "backgroundColor": NSNull()
        ]
        
        self.indicator_fg_layer = new_fg_layer
        
        let new_layer = CALayer()
        new_layer.name = "indicator"
        new_layer.bounds = bounds
        new_layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        new_layer.position = CGPoint(x: 0.0, y: 0.0)
        
        new_layer.shadowColor = CGColor.black
        new_layer.shadowOffset = CGSize(width: 0.0, height: 1.5)
        new_layer.shadowOpacity = 0.25
        new_layer.shadowRadius = 1.5
        
        new_layer.actions = [
            "position": NSNull()
        ]
        
        new_layer.addSublayer(new_bg_layer)
        new_layer.addSublayer(new_fg_layer)
        
        return new_layer
    }
    
    // MARK: - Mouse Event
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
            self.indicator_layer.actions?.removeValue(forKey: "position")
        } else {
            self.indicator_layer.actions?.updateValue(NSNull(), forKey: "position")
        }
        
        self.value = InterpolateUtils.interpolate(mu: Float(normalized.x), from: self.minValue, to: self.maxValue)
        
        self.indicator_layer.actions?.removeValue(forKey: "position")
    }
}

// MARK: -
// MARK: - Color Sliders
// MARK: -
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
        self.value = Float(L)
        self.setBackgroundColor(A: A, B: B)
    }
    
    func setBackgroundColor(A: CGFloat, B: CGFloat) {
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        
        self.current_a = A
        self.current_b = B
        
        let mid = (self.maxValue + self.minValue) / 2
        let min_mid = (self.minValue + mid) / 2
        let max_mid = (self.maxValue + mid) / 2
        
        self.background_layer.colors = [
            CGColor(colorSpace: color_space,
                    components: [CGFloat(self.minValue),A,B,1.0])!,
            CGColor(colorSpace: color_space,
                    components: [CGFloat(min_mid),A,B,1.0])!,
            CGColor(colorSpace: color_space,
                    components: [CGFloat(mid),A,B,1.0])!,
            CGColor(colorSpace: color_space,
                    components: [CGFloat(max_mid),A,B,1.0])!,
            CGColor(colorSpace: color_space,
                    components: [CGFloat(self.maxValue),A,B,1.0])!
        ]
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
        self.minValue = 0.0
        self.maxValue = 127.0
    }
    
    override func setLabColor(L: CGFloat, A: CGFloat, B: CGFloat, alpha: CGFloat = 1.0) {
        self.value = Float(A)
        self.setBackgroundColor(L: L, B: B)
    }
    
    func setBackgroundColor(L: CGFloat, B: CGFloat) {
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        
        self.current_l = L
        self.current_b = B
        
        let mid = (self.maxValue + self.minValue) / 2
        let min_mid = (self.minValue + mid) / 2
        let max_mid = (self.maxValue + mid) / 2
        
        self.background_layer.colors = [
            CGColor(colorSpace: color_space,
                    components: [L,CGFloat(self.minValue),B,1.0])!,
            CGColor(colorSpace: color_space,
                    components: [L,CGFloat(min_mid),B,1.0])!,
            CGColor(colorSpace: color_space,
                    components: [L,CGFloat(mid),B,1.0])!,
            CGColor(colorSpace: color_space,
                    components: [L,CGFloat(max_mid),B,1.0])!,
            CGColor(colorSpace: color_space,
                    components: [L,CGFloat(self.maxValue),B,1.0])!
        ]
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
        self.minValue = -128.0
        self.maxValue = 127.0
    }
    
    override func setLabColor(L: CGFloat, A: CGFloat, B: CGFloat, alpha: CGFloat = 1.0) {
        self.value = Float(B)
        self.setBackgroundColor(L: L, A: A)
    }
    
    func setBackgroundColor(L: CGFloat, A: CGFloat) {
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        
        self.current_l = L
        self.current_a = A
        
        let mid = (self.maxValue + self.minValue) / 2
        let min_mid = (self.minValue + mid) / 2
        let max_mid = (self.maxValue + mid) / 2
        
        self.background_layer.colors = [
            CGColor(colorSpace: color_space,
                    components: [L,A,CGFloat(self.minValue),1.0])!,
            CGColor(colorSpace: color_space,
                    components: [L,A,CGFloat(min_mid),1.0])!,
            CGColor(colorSpace: color_space,
                    components: [L,A,CGFloat(mid),1.0])!,
            CGColor(colorSpace: color_space,
                    components: [L,A,CGFloat(max_mid),1.0])!,
            CGColor(colorSpace: color_space,
                    components: [L,A,CGFloat(self.maxValue),1.0])!
        ]
        self.refreshIndicator()
    }
}

class AlphaColorSlider: LABColorSlider {
    override var current_alpha: CGFloat {
        get {
            return CGFloat(self.value)
        }
        set {}
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
        // bg layer
        let alpha_layer = CALayer()
        alpha_layer.cornerRadius = self.background_layer.cornerRadius
        alpha_layer.backgroundColor = Style.createDefaultCheckerColor()
        
        alpha_layer.constraints = [
            CAConstraint(attribute: .height, relativeTo: "background", attribute: .height),
            CAConstraint(attribute: .width, relativeTo: "background", attribute: .width),
            CAConstraint(attribute: .midX, relativeTo: "background", attribute: .midX),
            CAConstraint(attribute: .midY, relativeTo: "background", attribute: .midY)
        ]
        
        self.layer!.insertSublayer(alpha_layer, at: 0)
    }
    
    override func setLabColor(L: CGFloat, A: CGFloat, B: CGFloat, alpha: CGFloat) {
        self.value = Float(alpha)
        self.setBackgroundColor(L: L, A: A, B: B)
    }
    
    func setBackgroundColor(L: CGFloat, A: CGFloat, B: CGFloat) {
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        
        self.current_l = L
        self.current_a = A
        self.current_b = B
        
        self.background_layer.colors = [
            CGColor(colorSpace: color_space,
                    components: [L,A,B,0.0])!,
            CGColor(colorSpace: color_space,
                    components: [L,A,B,1.0])!
        ]
        self.refreshIndicator()
    }
}
