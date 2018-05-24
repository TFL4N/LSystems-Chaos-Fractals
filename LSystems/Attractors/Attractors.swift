//
//  Attractors.swift
//  StrangeAttractors
//
//  Created by Spizzace on 5/23/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation

class PickoverAttractor: Attractor {
    override init() {
        let params = [
            Parameter(name: "A", value: Value(type: .float, value: 0)),
            Parameter(name: "B", value: Value(type: .float, value: 0)),
            Parameter(name: "C", value: Value(type: .float, value: 0)),
            Parameter(name: "D", value: Value(type: .float, value: 0))
        ]
        
        super.init(parameters: params)!
    }
    
    override init?(parameters: [Parameter]) {
        // check parameters
        for p in ["A","B","C","D"] {
            if !parameters.contains(where: { (par: Parameter) -> Bool in
                return par.name == p
                    && par.value != nil
                    && par.value!.type == .float
            }) {
                return nil
            }
        }
        
        // init
        super.init(parameters: parameters)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let coder = aDecoder as! NSKeyedUnarchiver
        guard let params = coder.decodeObject(forKey: "attractor_parameters") as? [Parameter]
            else { return nil }
        
        self.init(parameters: params)
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
}

class Value: NSObject, NSCoding {
    let type: ValueType
    
    private var value_store: Any?
    var value: Any? {
        get {
            switch self.type {
            case .float:
                return self.value_store as? Float
            }
        }
        
        set {
            switch self.type {
            case .float:
                if let fl = newValue as? Float {
                    self.value_store = fl
                } else if let str = newValue as? String {
                    self.value_store = Float(str)
                } else if let fl = newValue as? NSNumber {
                    self.value_store = fl.floatValue
                }
            }
        }
    }
    
    var floatValue: Float? {
        return self.value as? Float
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
}

class Parameter: NSObject, NSCoding {
    let name: String
    var value: Value?
    
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
}
