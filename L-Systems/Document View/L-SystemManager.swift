//
//  L-SystemManager.swift
//  L-Systems
//
//  Created by Spizzace on 3/28/18.
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
        guard let variable = aDecoder.decodeObject(forKey: "variable") as? String,
            let value = aDecoder.decodeObject(forKey: "var_value") as? String
            else { return nil }
        
        self.init(variable: variable, value: value)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.variable, forKey: "variable")
        aCoder.encode(self.value, forKey: "var_value")
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
    
    override init() {
        super.init()
    }
    
    init(name: String, type: VariableType) {
        super.init()
        
        self.name = name
        self.type = type
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: "name") as? String,
            let type = aDecoder.decodeObject(forKey: "type") as? String
            else { return nil }
        
        self.init(name: name, type: VariableType(rawValue: type) ?? .NonDraw)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: "name")
        aCoder.encode(self.type.rawValue, forKey: "type")
    }
}

enum VariableType: String {
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
        let iterations = aDecoder.decodeInteger(forKey: "iterations")
        guard let axiom = aDecoder.decodeObject(forKey: "axiom") as? Axiom,
            let rules = aDecoder.decodeObject(forKey: "rules") as? [Rule],
            let variables = aDecoder.decodeObject(forKey: "variables") as? [Variable]
            else { return nil }
        
        self.init(axiom: axiom,
                  iterations: iterations,
                  rules: rules,
                  variables: variables)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.axiom, forKey: "axiom")
        aCoder.encode(self.iterations, forKey: "iterations")
        aCoder.encode(self.rules, forKey: "rules")
        aCoder.encode(self.variables, forKey: "variables")
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
}

class LSystemManager {
    var system: LSystem = LSystem()
    
    enum LSystemError: Error {
        case RuleNotFound
    }
    
    static let reservedCharacters = ["[","]","\\","|","/"]
    
    func createLSystemString() throws -> String {
        var str = self.system.axiom.value
        
        if self.system.iterations == 0 {
            return str
        }
        
        for _ in 1...self.system.iterations {
            var working = ""
            
            var range = str.startIndex...str.startIndex
            while range.upperBound < str.endIndex {
                let el = String(str[range])
                
                if !LSystemManager.reservedCharacters.contains(el) {
                    if let rule = self.system.rule(withVariableName: String(el)) {
                        working.append(rule.value)
                    } else {
                        throw LSystemError.RuleNotFound
                    }
                }
                
                // loop condition
                let index = str.index(after: range.upperBound)
                range = index...index
            }
            
            str = working
        }
        
        return str
    }
}
