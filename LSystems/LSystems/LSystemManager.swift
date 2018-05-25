//
//  L-SystemManager.swift
//  L-Systems
//
//  Created by Spizzace on 3/28/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation

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
    
    func findMaxAndMin(withVertices vertices: inout [Float]) -> (max_x: Float, min_x: Float, max_y: Float, min_y: Float) {
        var output = (max_x: Float(0.0), min_x: Float(0.0),
                      max_y: Float(0.0), min_y: Float(0.0))
        
        for i in 0..<vertices.count/3 {
            let x = vertices[i*3]
            let y = vertices[i*3+1]
            
            // x
            if x > output.max_x {
                output.max_x = x
            }
            if x < output.min_x {
                output.min_x = x
            }
            
            // y
            if y > output.max_y {
                output.max_y = y
            }
            if y < output.min_y {
                output.min_y = y
            }
        }
        
        return output
    }
    
    func buildTexCoordsBuffer(withVertices vertices: inout [Float]) -> [Float] {
        let extremes = self.findMaxAndMin(withVertices: &vertices)
        var output = [Float]()
        
        let x_range = extremes.max_x - extremes.min_x
        let y_range = extremes.max_y - extremes.min_y
        
        for i in 0..<vertices.count/3 {
            let x = vertices[i*3]
            let y = vertices[i*3+1]
            
            output.append((x - extremes.min_x) / x_range)
            output.append((y - extremes.min_y) / y_range)
        }
        
        return output
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
