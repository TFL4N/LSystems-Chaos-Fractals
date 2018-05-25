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
    case ColorMap = "ColorMap"
    
    static let allTypes = [None, ColorMap]
    static let allStringTypes = ColoringType.allTypes.map { $0.rawValue }
}

class ColorMap: NSObject, NSCoding {
    var filePath: String? = nil
    
    func encode(with aCoder: NSCoder) {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
    }
}

class LinearColor: NSObject, NSCoding {
    required init?(coder aDecoder: NSCoder) {
        
    }
    
    func encode(with aCoder: NSCoder) {
        
    }
}

class ColorInfo: NSObject, NSCoding {
    var coloringType: ColoringType = .None
    
    var colorMap: ColorMap? = nil
    
    var linearColor: LinearColor? = nil
    
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
        self.linearColor = coder.decodeObject(forKey: "colorinfo_linearcolor") as? LinearColor
    }
    
    func encode(with aCoder: NSCoder) {
        let coder = aCoder as! NSKeyedArchiver
        
        try! coder.encodeEncodable(self.coloringType, forKey: "colorinfo_type")
        coder.encode(self.colorMap, forKey: "colorinfo_colormap")
        coder.encode(self.linearColor, forKey: "colorinfo_linearcolor")
    }
}
