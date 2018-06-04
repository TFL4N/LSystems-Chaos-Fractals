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
    
    // MARK: - Interpolator
    class Interpolator {
        private let items: [GradientColorItem]
        let interpolating_color_space: CGColorSpace
        let output_color_space: CGColorSpace
        
        init?(color: GradientColor, interpolatingColorSpace: CGColorSpace, ouputColorSpace: CGColorSpace, outputsFloat: Bool = true) {
            var items = color.colors.map({ (item) -> GradientColorItem in
                let lab_color = item.color.converted(to: interpolatingColorSpace, intent: .absoluteColorimetric, options: nil)!
                return GradientColorItem(position: item.position, color: lab_color)
            })
            
            guard items.count >= 0 else {
                return nil
            }
            
            let first_item = items.first!
            if first_item.position != 0.0 {
                items.insert(GradientColorItem(position: 0.0, color: first_item.color.copy()!),
                             at: 0)
            }
            
            let last_item = items.last!
            if last_item.position != 1.0 {
                items.append(GradientColorItem(position: 1.0, color: last_item.color.copy()!))
            }
            
            self.items = items
            self.interpolating_color_space = interpolatingColorSpace
            self.output_color_space = ouputColorSpace
        }
        
        func interpolate(mu: Float) -> [Float] {
            let comps: [CGFloat] = self.interpolate(mu: mu)
            return comps.map { Float($0) }
        }
        
        func interpolate(mu: Float) -> [CGFloat] {
            return self.interpolate(mu: mu).components!
        }
        
        func interpolate(mu: Float) -> CGColor {
            let cg_mu = CGFloat(mu)
            let colors = self.getColors(mu: mu)
        
            var output_comps = [CGFloat](repeating: 0.0, count: self.interpolating_color_space.numberOfComponents)
            for i in 0..<self.interpolating_color_space.numberOfComponents {
                output_comps[i] = self.interpolate(mu: cg_mu,
                                                   from: colors.from.color.components![i],
                                                   to: colors.to.color.components![i])
            }
            
            let new_color = CGColor(colorSpace: self.interpolating_color_space, components: output_comps)!
            return new_color.converted(to: self.output_color_space, intent: .absoluteColorimetric, options: nil)!
        }
        
        private func getColors(mu: Float) -> (from: GradientColorItem, to: GradientColorItem) {
            if mu == 0.0 {
                return (self.items.first!, self.items.first!)
            } else if mu == 1.0 {
                return (self.items.last!, self.items.last!)
            }
            
            var output = (self.items.first!, self.items.last!)
            for (i,item) in self.items.enumerated() {
                if item.position > mu {
                    output = (self.items[i-1], item)
                    break
                }
            }
            
            return output
        }
        
        private func interpolate(mu: CGFloat, from: CGFloat, to: CGFloat) -> CGFloat {
            var val = (to - from) * mu
            val += from
            
            return val
        }
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