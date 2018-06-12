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
        new_bg_layer.actions = [
            "backgroundColor": NSNull(),
            "position": NSNull(),
            "bounds": NSNull()
        ]
        
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
            "position": NSNull(),
            "bounds": NSNull()
        ]
        
        self.gradient_layer = new_fg_layer
        
        let new_layer = CALayer()
        new_layer.addSublayer(new_bg_layer)
        new_layer.addSublayer(new_fg_layer)
        
        new_layer.layoutManager = CAConstraintLayoutManager()
        
        self.layer = new_layer
        self.wantsLayer = true
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
 
    func update(withGradientColor color: GradientColor) {
        let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
        guard let items = color.getInterpolatedGradientItems(interpolatingColorSpace: color_space, outputColorSpace: color_space) else {
            self.gradient_layer.colors = []
            self.gradient_layer.locations = []
            
            return
        }
        
        var colors = [CGColor]()
        var positions = [NSNumber]()
        
        for i in items {
            colors.append(i.color)
            positions.append(NSNumber(value: i.position))
        }
        
        self.gradient_layer.colors = colors
        self.gradient_layer.locations = positions
        
//        print("*************")
//        print(color)
//        print()
//        print(positions)
//        print(colors)
//        print("___________________")
    }
}
