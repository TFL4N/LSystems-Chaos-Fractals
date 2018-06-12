//
//  ColorWell.swift
//  L-Systems
//
//  Created by Spizzace on 6/3/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class ColorWell: NSView {
    var didClickHandler: ((ColorWell)->())? = nil
    var didSelectColor: ((CGColor)->())? = nil
    
    /// State
    enum ColorWellMode: Int {
        case displayOnly, colorPicker, custom
    }
    
    var mode: ColorWellMode = .colorPicker
    
    var isSelected: Bool = false {
        didSet {
            self.color_layer.borderColor = self.isSelected ? self.selectionColor : self.notSelectedColor
        }
    }
    
    /// Styling
    var selectionColor: CGColor = CGColor(gray: 0.35, alpha: 1.0) {
        didSet {
            if self.isSelected {
                self.color_layer.borderColor = self.selectionColor
            }
        }
    }
    
    var notSelectedColor: CGColor = CGColor(gray: 0.75, alpha: 1.0) {
        didSet {
            if !self.isSelected {
                self.color_layer.borderColor = self.notSelectedColor
            }
        }
    }
    
    var color: CGColor {
        get {
            return self.color_layer.backgroundColor!
        }
        
        set {
            self.color_layer.backgroundColor = newValue
        }
    }
    
    var hasAlphaChannel: Bool = true
    
    private var color_layer: CALayer!
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
        
        let new_fg_layer = CALayer()
        new_fg_layer.borderColor = self.notSelectedColor
        new_fg_layer.borderWidth = 3.0
        new_fg_layer.cornerRadius = corner_radius
        new_fg_layer.backgroundColor = CGColor.white
        new_fg_layer.constraints = ViewUtils.constraintsEqualSizeAndPosition(toLayer: "superlayer")
        new_fg_layer.actions = [
            "backgroundColor": NSNull(),
            "position": NSNull(),
            "bounds": NSNull()
        ]
        
        self.color_layer = new_fg_layer
        
        let new_layer = CALayer()
        new_layer.addSublayer(new_bg_layer)
        new_layer.addSublayer(new_fg_layer)
        
        new_layer.layoutManager = CAConstraintLayoutManager()
        
        self.layer = new_layer
        self.wantsLayer = true
        
        // gestures
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClickGesture(_:)))
        
        self.addGestureRecognizer(clickGesture)
        
        // notifications
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(handleColorPickerDidShowNotification(_:)),
                         name: ColorPickerViewController.ColorPickerDidShowNotification,
                         object: nil)
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    @objc private func handleClickGesture(_ gesture: NSClickGestureRecognizer) {
        switch self.mode {
        case .displayOnly:
            return
        case .custom:
            self.didClickHandler?(self)
        case .colorPicker:
            self.isSelected = true
            ColorPickerViewController
                .showColorPicker(sender: self,
                                 withColor: self.color)
                { (color) in
                    guard let color = color else {
                        return
                    }
                    
                    self.color = color
                    self.didSelectColor?(self.color)
            }
        }
    }
    
    @objc private func handleColorPickerDidShowNotification(_ notification: Notification) {
        if let sender = notification.userInfo?["sender"] as? ColorWell,
            sender == self{
            
        } else {
            self.isSelected = false
        }
    }
}
