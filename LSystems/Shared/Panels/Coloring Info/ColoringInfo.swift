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


@objcMembers
class ColoringInfo: NSObject, NSCoding {
    dynamic var coloringType: ColoringType {
        didSet {
            if oldValue != self.coloringType {
                self.didChange = true
            }
        }
    }
    
    dynamic var colorMap: ColorMap?
    
    dynamic var gradientColor: GradientColor? {
        willSet {
            if let color = self.gradientColor {
                color.removeObserver(self, forKeyPath: "didChange", context: nil)
            }
        }
        
        didSet {
            if let color = self.gradientColor {
                color.addObserver(self, forKeyPath: "didChange", options: [.initial, .new, .old], context: nil)
            }
        }
    }
    
    dynamic var didChange: Bool = false
    
    override convenience init() {
        self.init(type: .None, colorMap: nil, gradientColor: nil)
    }
    
    init(type: ColoringType, colorMap: ColorMap?, gradientColor: GradientColor?) {
        self.coloringType = type
        self.colorMap = colorMap
        self.gradientColor = nil
        super.init()
        
        // will call property observers
        defer {
            self.gradientColor = gradientColor
        }
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let coder = aDecoder as! NSKeyedUnarchiver
        guard let type = coder.decodeDecodable(ColoringType.self, forKey: "colorinfo_type") else {
            return nil
        }
        
        self.init(type: type,
                  colorMap: coder.decodeObject(forKey: "colorinfo_colormap") as? ColorMap,
                  gradientColor: coder.decodeObject(forKey: "colorinfo_linearcolor") as? GradientColor)
    }
    
    deinit {
        self.gradientColor = nil
    }
    
    func encode(with aCoder: NSCoder) {
        let coder = aCoder as! NSKeyedArchiver
        
        try! coder.encodeEncodable(self.coloringType, forKey: "colorinfo_type")
        coder.encode(self.colorMap, forKey: "colorinfo_colormap")
        coder.encode(self.gradientColor, forKey: "colorinfo_linearcolor")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "didChange" {
            if let change = change {
                let foo: (Bool, Bool?) = NSObjectUtils.observedValueDidChange(change)
                if foo.0 && foo.1! {
                    self.didChange = true
                }
            }
        }
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
    
    @objc dynamic var didChange: Bool = false
    
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
        
        self.didChange = true
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
        
        self.didChange = true
    }
    
    func removeColor(atIndex: Int) {
        let item = self.colors.remove(at: atIndex)
        
        for kp in GradientColor.key_paths {
            item.removeObserver(self, forKeyPath: kp, context: nil)
        }
        
        self.didChange = true
    }
    
    func alignedColorItems(inColorSpace color_space: CGColorSpace = CGColorSpace(name: CGColorSpace.genericLab)!) -> [GradientColorItem]? {
        var items = self.colors.map({ (item) -> GradientColorItem in
            let lab_color = item.color.converted(to: color_space, intent: .absoluteColorimetric, options: nil)!
            return GradientColorItem(position: item.position, color: lab_color)
        })
        
        guard items.count > 0 else {
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
        
        return items
    }
    
    func getMTLGradientColorItems() -> [A_ColorItem]? {
        return self.alignedColorItems(inColorSpace: CGColorSpace(name: CGColorSpace.genericLab)!)?.map({ (item) -> A_ColorItem in
            return A_ColorItem(
                color: vector_float4(item.color.fromLABtoMTLColor()),
                position: item.position)
        })
    }
    
    // MARK: - Interpolator
    class Interpolator {
        private let items: [GradientColorItem]
        let interpolating_color_space: CGColorSpace
        let output_color_space: CGColorSpace
        
        init?(color: GradientColor, interpolatingColorSpace: CGColorSpace, outputColorSpace: CGColorSpace, outputsFloat: Bool = true) {
            guard let items = color.alignedColorItems(inColorSpace: interpolatingColorSpace) else {
                return nil
            }
            
            self.items = items
            self.interpolating_color_space = interpolatingColorSpace
            self.output_color_space = outputColorSpace
        }
        
        func interpolate(mu: Float) -> [Float] {
            let comps: [CGFloat] = self.interpolate(mu: mu)
            return comps.map { Float($0) }
        }
        
        func interpolate(mu: Float) -> [CGFloat] {
            return self.interpolate(mu: mu).components!
        }
        
        func interpolate(mu: Float) -> CGColor {
            let colors = self.getColors(mu: mu)
            
            let from = colors.from.position
            let to = colors.to.position
            let local_mu: CGFloat
            if from == to {
                local_mu = 1.0
            } else {
                local_mu = CGFloat( (mu - from) / (to - from) )
            }
            
            let comps_count = self.interpolating_color_space.numberOfComponents + 1
            var output_comps = [CGFloat](repeating: 0.0, count:comps_count)
            for i in 0..<comps_count {
                output_comps[i] = InterpolateUtils.interpolate(mu: local_mu,
                                              from: colors.from.color.components![i],
                                              to: colors.to.color.components![i])
            }
            
//            print("*****************")
//            print(mu)
//            print(colors.from.color.components!)
//            print(colors.to.color.components!)
//            print("** \(output_comps)")
//            print("-------------------")
            
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
