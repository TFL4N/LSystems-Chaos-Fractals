//
//  L-SystemManager.swift
//  L-Systems
//
//  Created by Spizzace on 3/28/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation

class Rule: NSCoding {
    var variable: String = ""
    var value: String = ""
    
    init() {
        
    }
    
    init(variable: String, value: String) {
        self.variable = variable
        self.value = value
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let variable = aDecoder.decodeObject(forKey: "variable") as? String,
            let value = aDecoder.decodeObject(forKey: "value") as? String
            else { return nil }
        
        self.init(variable: variable, value: value)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.variable, forKey: "variable")
        aCoder.encode(self.value, forKey: "value")
    }
}

class Axiom: NSCoding {
    var value: String = ""
    
    init() {
        
    }
    
    init(value: String) {
        self.value = value
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let value = aDecoder.decodeObject(forKey: "value") as? String
            else { return nil }
        
        self.init(value: value)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.value, forKey: "value")
    }
}

class Variable: NSCoding {
    var name: String = ""
    var type: VariableType = .Draw
    
    init() {
        
    }
    
    init(name: String, type: VariableType) {
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

class LSystem: NSCoding {
    var axiom = Axiom()
    var iterations: Int = 0
    var rules: [Rule] = []
    var variables: [Variable] = []
    
    init() {
        
    }
    
    init(axiom: Axiom, iterations: Int, rules: [Rule], variables: [Variable]) {
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
}

class LSystemManager {
    var system: LSystem = LSystem()
    
    func createLSystemString() -> String {
        var str = self.system.axiom.value
        
        return str
    }
}
