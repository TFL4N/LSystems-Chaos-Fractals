//
//  ColorInfo.swift
//  L-Systems
//
//  Created by Spizzace on 5/9/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

enum ColoringType: String, Codable {
    case None = "None"
    case Gradient = "Gradient"
    case ColorMap = "ColorMap"
    
    static let allTypes = [None, Gradient, ColorMap]
    static let allStringTypes = ColoringType.allTypes.map { $0.rawValue }
}


class ColoringInfo: NSObject, NSCoding {
    var coloringType: ColoringType = .None
    
    var colorMap: ColorMap? = nil
    
    var gradientColor: GradientColor? = nil
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        let coder = aDecoder as! NSKeyedUnarchiver
        guard let type = coder.decodeDecodable(ColoringType.self, forKey: "colorinfo_type") else {
            return nil
        }
        
        self.coloringType = type
        self.colorMap = coder.decodeObject(forKey: "colorinfo_colormap") as? ColorMap
        self.gradientColor = coder.decodeObject(forKey: "colorinfo_linearcolor") as? GradientColor
    }
    
    func encode(with aCoder: NSCoder) {
        let coder = aCoder as! NSKeyedArchiver
        
        try! coder.encodeEncodable(self.coloringType, forKey: "colorinfo_type")
        coder.encode(self.colorMap, forKey: "colorinfo_colormap")
        coder.encode(self.gradientColor, forKey: "colorinfo_linearcolor")
    }
}

class ColorMap: NSObject, NSCoding {
    var filePath: String? = nil
    
    func encode(with aCoder: NSCoder) {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
    }
}

class GradientColor: NSObject, NSCoding {
    private(set) var colors: [GradientColorItem]
    
    var didChangeHandler: ((GradientColor)->())?
    
    override convenience init() {
        self.init(colors: [])
    }
    
    init(colors: [GradientColorItem]) {
        self.colors = colors
        super.init()
        
        for item in self.colors {
            for kp in GradientColor.key_paths {
                item.addObserver(self, forKeyPath: kp, options: [.new], context: nil)
            }
        }
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let coder = aDecoder as! NSKeyedUnarchiver
        guard let colors = coder.decodeObject(forKey: "gradientcolor_colors") as? [GradientColorItem] else {
            return nil
        }
        
        self.init(colors: colors)
    }
    
    deinit {
        for item in self.colors {
            for kp in GradientColor.key_paths {
                item.removeObserver(self, forKeyPath: kp, context: nil)
            }
        }
    }
    
    func encode(with aCoder: NSCoder) {
        let coder = aCoder as! NSKeyedArchiver
        
        coder.encode(self.colors, forKey: "gradientcolor_colors")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == GradientColor.key_paths[0] {
            self.sortColors()
        }
        
        self.didChangeHandler?(self)
    }
    
    private func sortColors() {
        self.colors.sort { (lhs, rhs) -> Bool in
            return lhs.position < rhs.position
        }
    }
    
    private static let key_paths = ["position", "nscolor"]
    func addColor(_ color: CGColor, atPosition position: Float) {
        let item = GradientColorItem(position: position, color: color)
        for kp in GradientColor.key_paths {
            item.addObserver(self, forKeyPath: kp, options: [.new], context: nil)
        }
        
        
        self.colors.append(item)
        self.sortColors()
        
        self.didChangeHandler?(self)
    }
    
    func removeColor(atIndex: Int) {
        let item = self.colors.remove(at: atIndex)
        
        for kp in GradientColor.key_paths {
            item.removeObserver(self, forKeyPath: kp, context: nil)
        }
        
        self.didChangeHandler?(self)
    }
}

class GradientColorItem: NSObject, NSCoding {
    @objc dynamic var position: Float
    var color: CGColor {
        willSet {
            self.willChangeValue(forKey: "nscolor")
        }
        
        didSet {
            self.didChangeValue(forKey: "nscolor")
        }
    }
    
    @objc dynamic var nscolor: NSColor {
        get {
            return NSColor(cgColor: self.color)!
        }
        
        set {
            self.color = newValue.cgColor
        }
    }
    
    convenience override init() {
        self.init(position: 0.0, color: CGColor.white)
    }
    
    init(position: Float, color: CGColor) {
        self.position = position
        self.color = color
        
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let coder = aDecoder as! NSKeyedUnarchiver
        guard let color = coder.decodeObject(forKey: "gradientcolor_item_color") as? NSColor else {
            return nil
        }
        
        let pos = coder.decodeFloat(forKey: "gradientcolor_item_position")
        
        self.init(position: pos, color: color.cgColor)
    }
    
    func encode(with aCoder: NSCoder) {
        let coder = aCoder as! NSKeyedArchiver
        
        coder.encode(self.position, forKey: "gradientcolor_item_position")
        coder.encode(self.nscolor, forKey: "gradientcolor_item_color")
    }
}
