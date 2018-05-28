//
//  Attractors.swift
//  StrangeAttractors
//
//  Created by Spizzace on 5/23/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation

extension NSCoding {
    func deepCopy() -> Self {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as! Self
    }
}

class Attractor: NSObject, NSCoding {
    let parameters: [Parameter]
    
    override init() {
        self.parameters = []
        super.init()
    }
    
    init?(parameters: [Parameter]) {
        self.parameters = parameters
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let coder = aDecoder as! NSKeyedUnarchiver
        guard let parameters = coder.decodeObject(forKey: "attractor_parameters") as? [Parameter]
            else { return nil }
        
        self.init(parameters: parameters)
    }
    
    func encode(with aCoder: NSCoder) {
        let coder = aCoder as! NSKeyedArchiver
        
        coder.encode(self.parameters, forKey: "attractor_parameters")
    }
    
    
    
    func buildVertexArray() -> [Float] {
        return self.buildVertexArray(atFrame: 0)
    }
    
    func buildVertexArray(atFrame: FrameId) -> [Float] {
        return []
    }
    
    func parameter(withName name: String) -> Parameter? {
        if let idx = self.parameters.index(where: { (p) -> Bool in
            p.name == name
        }) {
            return self.parameters[idx]
        }
        
        return nil
    }
}

class Value: NSObject, NSCoding {
    let type: ValueType
    
    @objc dynamic private var value_store: Any?
    var value: Any? {
        get {
            switch self.type {
            case .float:
                return self.value_store as? Float
            case .integer:
                return self.value_store as? Int
            }
        }
        
        set {
            guard let new_val = newValue else {
                self.value_store = nil
                return
            }
            
            switch self.type {
            case .float:
                if let fl = new_val as? Float {
                    self.value_store = fl
                } else if let i = new_val as? Int {
                    self.value_store = Float(i)
                } else if let str = new_val as? String {
                    self.value_store = Float(str)
                } else if let fl = new_val as? NSNumber {
                    self.value_store = fl.floatValue
                }
            case .integer:
                if let i = new_val as? Int {
                    self.value_store = i
                } else if let fl = new_val as? Float {
                    self.value_store = Int(fl)
                } else if let str = new_val as? String {
                    self.value_store = Int(str)
                } else if let n = new_val as? NSNumber {
                    self.value_store = n.intValue
                }
            }
        }
    }
    
    var floatValue: Float? {
        get {
            return self.value as? Float
        }
        
        set {
            self.value = newValue
        }
    }
    
    var integerValue: Int? {
        get {
            return self.value as? Int
        }
        
        set {
            self.value = newValue
        }
    }
    
    @objc dynamic var numberValue: NSNumber? {
        get {
            switch self.type {
            case .float:
                return NSNumber(value: self.floatValue!)
            case .integer:
                return NSNumber(value: self.integerValue!)
            }
        }
        
        set {
            self.value = newValue
        }
    }
    
    
    @objc dynamic class func keyPathsForValuesAffectingNumberValue() -> Set<String> {
        return ["value_store"]
    }
    
    var stringValue: String? {
        if let val = self.value {
            return "\(val)"
        } else {
            return nil
        }
    }
    
    init(type: ValueType, value: Any?) {
        self.type = type
        
        super.init()
        
        self.value = value
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let coder = aDecoder as! NSKeyedUnarchiver
        guard let type = coder.decodeDecodable(ValueType.self, forKey: "value_type"),
            let value = coder.decodeObject(forKey: "value_value")
            else { return nil }
        
        self.init(type: type, value: value)
    }
    
    func encode(with aCoder: NSCoder) {
        let coder = aCoder as! NSKeyedArchiver
        
        try! coder.encodeEncodable(self.type, forKey: "value_type")
        coder.encode(self.value, forKey: "value_value")
    }
}

enum ValueType: String, Codable {
    case float =  "float"
    case integer = "integer"
}

class Parameter: NSObject, NSCoding {
    let name: String
    var value: Value?
    var animation: AnimationSequence?
    
    init(name: String, value: Value?) {
        self.name = name
        self.value = value
        
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let coder = aDecoder as! NSKeyedUnarchiver
        guard let name = coder.decodeObject(forKey: "parameter_name") as? String
            else { return nil }
        
        let value = coder.decodeObject(forKey: "parameter_value") as? Value
        
        self.init(name: name, value: value)
    }
    
    func encode(with aCoder: NSCoder) {
        let coder = aCoder as! NSKeyedArchiver
        
        coder.encode(self.name, forKey: "parameter_name")
        coder.encode(self.value, forKey: "parameter_value")
    }
    
    func value(atFrame: FrameId) -> Value? {
        guard let anim = self.animation, anim.key_frames.count > 0 else {
            return self.value
        }
        
        // find the current key frame
        var min_frame_id: UInt = 0
        var min_key_frame = anim.key_frames[0]
        var max_key_frame = min_key_frame
        
        for (i, key_frame) in anim.key_frames.enumerated() {
            let new_frame = min_frame_id + key_frame.duration
            if new_frame < atFrame {
                min_frame_id = new_frame
                continue
            } else {
                // found min key frame
                min_key_frame = key_frame
                if i + 1 < anim.key_frames.count {
                    max_key_frame = anim.key_frames[i+1]
                } else {
                    max_key_frame = min_key_frame
                }
                
                break
            }
        }
        
//        print("**********")
//        print(atFrame)
//        print(min_frame_id)
//        print(min_key_frame.value.floatValue!)
//        print(max_key_frame.value.floatValue!)
//        print("****===***")
        
        // interpolate value
        let position = Float(atFrame - min_frame_id) / Float(min_key_frame.duration)
        
        
        return anim.interpolator.interpolate(at: position,
                                             fromValue: min_key_frame.value,
                                             toValue: max_key_frame.value)
    }
}

class AnimationSequence {
    var key_frames: [KeyFrame]
    var interpolator: Interpolator = LinearInterpolator()
    
    init(keyFrames: [KeyFrame]) {
        self.key_frames = keyFrames
    }
}

protocol Interpolator {
    // @param at: the current position, represented on the scale 0.0 -> 1.0
    func interpolate(at: Float, fromValue: Value, toValue: Value) -> Value
}

class LinearInterpolator: Interpolator {
    func interpolate(at pos: Float, fromValue: Value, toValue: Value) -> Value {
        let to = toValue.floatValue!
        let from = fromValue.floatValue!
        
        var val = (to - from) * pos
        val += from
        
        return Value(type: .float, value: val)
    }
}

class KeyFrame {
    var value: Value
    var duration: FrameInterval
    
    init(value: Value, duration: FrameInterval) {
        self.value = value
        self.duration = duration
    }
}
