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
        guard let name = aDecoder.decodeObject(forKey: "variable_name") as? String,
            let type = aDecoder.decodeObject(forKey: "variable_type") as? String,
            let value = aDecoder.decodeObject(forKey: "variable_value") as? String
            else { return nil }
        
        self.init(name: name,
                  type: VariableType(rawValue: type) ?? .NonDraw,
                  value: value)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: "variable_name")
        aCoder.encode(self.type.rawValue, forKey: "variable_type")
        aCoder.encode(self.value, forKey: "variable_value")
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

class LSystemManager {
    var system: LSystem = LSystem()
    var output_str: String? = nil
    
    enum LSystemError: Error {
        case RuleNotFound
        case UnsupportedReserveCharacter
        case MissingAngleVariable
    }
    
    static let reservedCharacters = ["[","]","\\","|","/","-","+"]
    
    init(l_system: LSystem) {
        self.system = l_system
    }
    
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
                
                if LSystemManager.reservedCharacters.contains(el) {
                    working.append(el)
                } else {
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
        
        self.output_str = str
        return self.output_str!
    }
    
    func buildLineVertexBuffer() throws -> [Float] {
        // working string
        let working: String
        if let str = self.output_str {
            working = str
        } else {
            working = try self.createLSystemString()
        }
        
        // output buffer
        var outputBuffer = Array<Float>()
        outputBuffer.reserveCapacity(self.output_str!.count * 2 * 3)
        
        // angle var
        let angleVar = self.system.firstAngleVariable()
        let angleValue: Float?
        if let val = angleVar?.value  {
            angleValue = Float(val)
        } else {
            angleValue = nil
        }
        
        // state info
        var currentPos: Position = Position()
        var currentAngle: Float = 0.0
        var currentRange = working.startIndex...working.startIndex
        var currentSegmentLength: Float = 1.0
        
        let positionStack = PositionStack()
        let ruleMap = self.mapRules()
        
        while currentRange.upperBound < working.endIndex {
            let el = String(working[currentRange])
            
            if LSystemManager.reservedCharacters.contains(el) {
                if ["[","]","-","+"].contains(el) {
                    guard angleValue != nil else {
                        throw LSystemError.MissingAngleVariable
                    }
                }
                
                switch el {
                case "[":
                    positionStack.push((currentPos, currentAngle))
                case "]":
                    (currentPos, currentAngle) = positionStack.pop()
                case "-":
                    currentAngle -= angleValue!
                case "+":
                    currentAngle += angleValue!
                default:
                    throw LSystemError.UnsupportedReserveCharacter
                }
            } else {
                guard let rule = ruleMap.first(where: { (item) -> Bool in
                    if let variable = item.variable {
                        return variable.name == el
                    } else {
                        return false
                    }
                }) else {
                    throw LSystemError.RuleNotFound
                }
                
                if let variable = rule.variable {
                    if variable.type == .Draw {
                        // append current pos
                        appendPosition(currentPos, buffer: &outputBuffer)
                        
                        // move turtle
                        let new_x = sinf(radians_from_degrees(currentAngle)) * currentSegmentLength
                        let new_y = cosf(radians_from_degrees(currentAngle)) * currentSegmentLength
                        let new_z = Float(0.0)
                        
                        currentPos += Position(x: new_x, y: new_y, z: new_z)
                        
                        // append new pos
                        appendPosition(currentPos, buffer: &outputBuffer)
                    }
                }
            }
            
            // loop condition
            let index = working.index(after: currentRange.upperBound)
            currentRange = index...index
        }
        
        return outputBuffer
    }
    
    private func appendPosition(_ position: Position, buffer: inout [Float]) {
        buffer.append(position.x)
        buffer.append(position.y)
        buffer.append(position.z)
    }
    
    private func mapRules() -> [RuleMapItem] {
        var output: [RuleMapItem] = []
        for r in self.system.rules {
            output.append(RuleMapItem(rule: r, l_system: &self.system))
        }
        
        return output
    }
    
    struct Position {
        var x: Float
        var y: Float
        var z: Float
        
        init() {
            self.x = 0.0
            self.y = 0.0
            self.z = 0.0
        }
        
        init(x: Float, y: Float, z: Float) {
            self.x = x
            self.y = y
            self.z = z
        }
        
        static func +(_ p1: Position, _ p2: Position) -> Position {
            return Position(x: p1.x + p2.x,
                            y: p1.y + p2.y,
                            z: p1.z + p2.z)
        }
        
        static func +=(_ p1: inout Position, _ p2: Position) {
            p1.x += p2.x
            p1.y += p2.y
            p1.z += p2.z
        }
    }
    
    class PositionStack {
        typealias Element = (pos: Position, angle: Float)
        
        private var stack: [Element] = []
        
        func push(pos: Position, angle: Float) {
            self.push((pos,angle))
        }
        
        func push(_ element: Element) {
            stack.append(element)
        }
        
        func pop() -> Element {
            return stack.removeLast()
        }
    }
    
    class RuleMapItem {
        let rule: Rule
        let variable: Variable?
        
        init(rule: Rule, l_system: inout LSystem) {
            self.rule = rule
            self.variable = l_system.variable(withName: self.rule.variable)
        }
    }
}
