//
//  GradientColorWell.swift
//  L-Systems
//
//  Created by Spizzace on 6/3/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class GradientColorWell: NSView {
    private var gradient_layer: CAGradientLayer!
    private var background_layer: CALayer!
    
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
        let corner_radius: CGFloat = 5.0
        
        let new_bg_layer = CALayer()
        new_bg_layer.backgroundColor = Style.createDefaultCheckerColor()
        new_bg_layer.cornerRadius = corner_radius
        new_bg_layer.constraints = ViewUtils.constraintsEqualSizeAndPosition(toLayer: "superlayer")
        
        self.background_layer = new_bg_layer
        
        let new_fg_layer = CAGradientLayer()
        new_fg_layer.borderColor = CGColor(gray: 0.75, alpha: 1.0)
        new_fg_layer.borderWidth = 3.0
        new_fg_layer.cornerRadius = corner_radius
        new_fg_layer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        new_fg_layer.colors = [CGColor.white, CGColor.black]
        new_fg_layer.locations = [0.0, 1.0]
        new_fg_layer.constraints = ViewUtils.constraintsEqualSizeAndPosition(toLayer: "superlayer")
        new_fg_layer.actions = [
            "backgroundColor": NSNull(),
            "colors": NSNull(),
            "position": NSNull()
        ]
        
        self.gradient_layer = new_fg_layer
        
        let new_layer = CALayer()
        new_layer.addSublayer(new_bg_layer)
        new_layer.addSublayer(new_fg_layer)
        
        new_layer.layoutManager = CAConstraintLayoutManager()
        
        self.layer = new_layer
        self.wantsLayer = true
    }
 
    func update(withGradientColor color: GradientColor) {
        if color.colors.count == 0 {
            self.gradient_layer.colors = []
            self.gradient_layer.locations = []
        } else if color.colors.count == 1 {
            self.gradient_layer.colors = [color.colors[0],color.colors[0]]
            self.gradient_layer.locations = []
        }
        
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        let interpolator = GradientColor.Interpolator(color: color,
                                                      interpolatingColorSpace: color_space,
                                                      outputColorSpace: color_space)!
        
        var colors: [CGColor] = [color.colors[0].color]
        var positions: [NSNumber] = [0.0]
        
        
        for i in 1..<color.colors.count {
            let first_color = color.colors[i-1]
            let second_color = color.colors[i]
            
            let min = first_color.position
            let max = second_color.position
            
            let min_mid = InterpolateUtils.interpolate(mu: 0.25, from: min, to: max)
            let mid = InterpolateUtils.interpolate(mu: 0.5, from: min, to: max)
            let max_mid = InterpolateUtils.interpolate(mu: 0.75, from: min, to: max)
            
            let new_positions = [
                min_mid, mid, max_mid, max
            ]
            
            for pos in new_positions {
                colors.append(interpolator.interpolate(mu: pos))
                positions.append(NSNumber(value: pos))
            }
        }
        
//        print(positions)
//        print(colors)
//        print()
        
        self.gradient_layer.colors = colors
        self.gradient_layer.locations = positions
    }
}
