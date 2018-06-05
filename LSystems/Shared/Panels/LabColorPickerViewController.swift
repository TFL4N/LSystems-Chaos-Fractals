//
//  LabColorPickerViewController.swift
//  L-Systems
//
//  Created by Spizzace on 6/2/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class ColorPickerViewController: LabColorPickerViewController {
    static let ColorPickerDidShowNotification = Notification.Name("color_picker_did_show_notification")
    
    static private(set) var sharedColorPickerWindow: NSWindowController = {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        
        return storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Color Picker Panel")) as! NSWindowController
    }()
    
    static var sharedColorPicker: LabColorPickerViewController {
        return self.sharedColorPickerWindow.contentViewController as! LabColorPickerViewController
    }
    
    static func showColorPicker(sender: Any?, withColor: CGColor, completionHandler: ((CGColor?)->())?) {
        self.sharedColorPicker.color = withColor
        self.sharedColorPicker.completionHandler = completionHandler
        
        if !self.sharedColorPickerWindow.window!.isVisible {
            self.sharedColorPickerWindow.showWindow(nil)
        }
        
        NotificationCenter.default.post(name: self.ColorPickerDidShowNotification, object: nil, userInfo: ["sender": sender ?? NSNull()])
    }
}

class LabColorPickerViewController: NSViewController {

    @IBOutlet var l_color_slider: LColorSlider!
    @IBOutlet var a_color_slider: AColorSlider!
    @IBOutlet var b_color_slider: BColorSlider!
    @IBOutlet var alpha_color_slider: AlphaColorSlider!
    
    @IBOutlet var l_color_textfield: NSTextField!
    @IBOutlet var a_color_textfield: NSTextField!
    @IBOutlet var b_color_textfield: NSTextField!
    @IBOutlet var alpha_color_textfield: NSTextField!
    
    @IBOutlet var alpha_container_view: NSView!
    
    @IBOutlet var current_color_well: ColorWell!

    var showsAlpha: Bool = true {
        didSet {
            self.alpha_container_view?.isHidden = !self.showsAlpha
        }
    }
    
    var completionHandler: ((CGColor)->())? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.current_color_well.mode = .custom
        self.current_color_well.didClickHandler = { (_) in
            self.completionHandler?(self.color)
        }
        
        self.l_color_textfield.formatter = NumberFormatter.buildFloatFormatter(min: self.l_color_slider.minValue, max: self.l_color_slider.maxValue)
        self.a_color_textfield.formatter = NumberFormatter.buildFloatFormatter(min: self.a_color_slider.minValue, max: self.a_color_slider.maxValue)
        self.b_color_textfield.formatter = NumberFormatter.buildFloatFormatter(min: self.b_color_slider.minValue, max: self.b_color_slider.maxValue)
        self.alpha_color_textfield.formatter = NumberFormatter.buildFloatFormatter(min: self.alpha_color_slider.minValue, max: self.alpha_color_slider.maxValue)
        
        self.l_color_textfield.bind(.value, to: self.l_color_slider, withKeyPath: "value", options: nil)
        self.a_color_textfield.bind(.value, to: self.a_color_slider, withKeyPath: "value", options: nil)
        self.b_color_textfield.bind(.value, to: self.b_color_slider, withKeyPath: "value", options: nil)
        self.alpha_color_textfield.bind(.value, to: self.alpha_color_slider, withKeyPath: "value", options: nil)
        
        self.l_color_slider.addObserver(self, forKeyPath: "value", options: [.new], context: nil)
        self.a_color_slider.addObserver(self, forKeyPath: "value", options: [.new], context: nil)
        self.b_color_slider.addObserver(self, forKeyPath: "value", options: [.new], context: nil)
        self.alpha_color_slider.addObserver(self, forKeyPath: "value", options: [.new], context: nil)
        
        self.alpha_container_view.isHidden = !self.showsAlpha
    }
    
    deinit {
        self.l_color_slider.removeObserver(self, forKeyPath: "value", context: nil)
        self.a_color_slider.removeObserver(self, forKeyPath: "value", context: nil)
        self.b_color_slider.removeObserver(self, forKeyPath: "value", context: nil)
        self.alpha_color_slider.removeObserver(self, forKeyPath: "value", context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let obj = object as? LABColorSlider else {
            return
        }
        
        let color = self.color
        let comps = color.components!
        let L = comps[0]
        let A = comps[1]
        let B = comps[2]
        
        if self.l_color_slider == obj {
            self.a_color_slider.setBackgroundColor(L: L, B: B)
            self.b_color_slider.setBackgroundColor(L: L, A: A)
            self.alpha_color_slider.setBackgroundColor(L: L, A: A, B: B)
        } else if self.a_color_slider == obj {
            self.l_color_slider.setBackgroundColor(A: A, B: B)
            self.b_color_slider.setBackgroundColor(L: L, A: A)
            self.alpha_color_slider.setBackgroundColor(L: L, A: A, B: B)
        } else if self.b_color_slider == obj {
            self.l_color_slider.setBackgroundColor(A: A, B: B)
            self.a_color_slider.setBackgroundColor(L: L, B: B)
            self.alpha_color_slider.setBackgroundColor(L: L, A: A, B: B)
        }
        
        self.current_color_well.color = color
    }
    
    var color: CGColor {
        get {
            let color_space = CGColorSpace(name: CGColorSpace.genericLab)!
            return CGColor(colorSpace: color_space, components: [
                CGFloat(self.l_color_slider.value),
                CGFloat(self.a_color_slider.value),
                CGFloat(self.b_color_slider.value),
                self.showsAlpha ? CGFloat(self.alpha_color_slider.value) : 1.0
                ])!
        }
        
        set {
            let lab_color_space = CGColorSpace(name: CGColorSpace.genericLab)!
            let lab_color = newValue.converted(to: lab_color_space, intent: .absoluteColorimetric, options: nil)
            
            if let lab_color = lab_color {
                self.l_color_slider.setLabColor(lab_color)
                self.a_color_slider.setLabColor(lab_color)
                self.b_color_slider.setLabColor(lab_color)
                self.alpha_color_slider.setLabColor(lab_color)
                
                self.current_color_well.color = color
            }
        }
    }
}
