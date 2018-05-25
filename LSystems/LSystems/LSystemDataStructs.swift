//
//  LSystemDataStructs.swift
//  L-Systems
//
//  Created by Spizzace on 5/24/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation


class Rule: NSObject, NSCoding {
    var variable: String = ""
    var value: String = ""
    
    override init() {
        super.init()
    }
    
    init(variable: String, value: String) {
        super.init()
        
        self.variable = variable
        self.value = value
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let variable = aDecoder.decodeObject(forKey: "rule_variable") as? String,
            let value = aDecoder.decodeObject(forKey: "rule_value") as? String
            else { return nil }
        
        self.init(variable: variable, value: value)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.variable, forKey: "rule_variable")
        aCoder.encode(self.value, forKey: "rule_value")
    }
}

class Axiom: NSObject, NSCoding {
    var value: String = ""
    
    override init() {
        super.init()
    }
    
    init(value: String) {
        super.init()
        
        self.value = value
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let value = aDecoder.decodeObject(forKey: "axiom_value") as? String
            else { return nil }
        
        self.init(value: value)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.value, forKey: "axiom_value")
    }
}

class Variable: NSObject, NSCoding {
    var name: String = ""
    var type: VariableType = .Draw
    var value: String = ""
    
    override init() {
        super.init()
    }
    
    init(name: String, type: VariableType, value: String) {
        super.init()
        
        self.name = name
        self.type = type
        self.value = value
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let coder = aDecoder as! NSKeyedUnarchiver
        guard let name = coder.decodeObject(forKey: "variable_name") as? String,
            let type = coder.decodeDecodable(VariableType.self, forKey: "variable_type"),
            let value = coder.decodeObject(forKey: "variable_value") as? String
            else { return nil }
        
        self.init(name: name,
                  type: type,
                  value: value)
    }
    
    func encode(with aCoder: NSCoder) {
        let coder = aCoder as! NSKeyedArchiver
        
        coder.encode(self.name, forKey: "variable_name")
        try! coder.encodeEncodable(self.type, forKey: "variable_type")
        coder.encode(self.value, forKey: "variable_value")
    }
}

enum VariableType: String, Codable {
    case Draw = "Draw"
    case NonDraw = "Non-Draw"
    case Angle = "Angle"
    
    static let allTypes = [Draw, NonDraw, Angle]
    static let allTypeStrings = VariableType.allTypes.map {$0.rawValue}
}

class LSystem: NSObject, NSCoding {
    var axiom = Axiom()
    var iterations: Int = 0
    var rules: [Rule] = []
    var variables: [Variable] = []
    
    override init() {
        super.init()
    }
    
    init(axiom: Axiom, iterations: Int, rules: [Rule], variables: [Variable]) {
        super.init()
        
        self.axiom = axiom
        self.iterations = iterations
        self.rules = rules
        self.variables = variables
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let iterations = aDecoder.decodeInteger(forKey: "lsystem_iterations")
        guard let axiom = aDecoder.decodeObject(forKey: "lsystem_axiom") as? Axiom,
            let rules = aDecoder.decodeObject(forKey: "lsystem_rules") as? [Rule],
            let variables = aDecoder.decodeObject(forKey: "lsystem_variables") as? [Variable]
            else { return nil }
        
        self.init(axiom: axiom,
                  iterations: iterations,
                  rules: rules,
                  variables: variables)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.axiom, forKey: "lsystem_axiom")
        aCoder.encode(self.iterations, forKey: "lsystem_iterations")
        aCoder.encode(self.rules, forKey: "lsystem_rules")
        aCoder.encode(self.variables, forKey: "lsystem_variables")
    }
    
    func addNewRule() {
        self.rules.append(Rule())
    }
    
    func addNewVariable() {
        self.variables.append(Variable())
    }
    
    func rule(withVariableName name: String) -> Rule? {
        for r in self.rules {
            if r.variable == name {
                return r
            }
        }
        
        return nil
    }
    
    func variable(withName name: String) -> Variable? {
        for v in self.variables {
            if v.name == name {
                return v
            }
        }
        
        return nil
    }
    
    func firstAngleVariable() -> Variable? {
        for v in self.variables {
            if v.type == .Angle {
                return v
            }
        }
        
        return nil
    }
}
