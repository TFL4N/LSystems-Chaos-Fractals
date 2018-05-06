//
//  L-SystemManager.swift
//  L-Systems
//
//  Created by Spizzace on 3/28/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation

class Rule {
    var variable: String = ""
    var value: String = ""
}

class Axiom {
    var value: String = ""
}

class Variable {
    var name: String = ""
    var type: VariableType = .Draw
}

enum VariableType: String {
    case Draw = "Draw"
    case NonDraw = "Non-Draw"
    case Angle = "Angle"
    
    static let allTypes = [Draw, NonDraw, Angle]
    static let allTypeStrings = VariableType.allTypes.map {$0.rawValue}
}

class LSystem {
    var axiom = Axiom()
    var iterations: Int = 0
    var rules: [Rule] = []
    var variables: [Variable] = []
    
    func addNewRule() {
        self.rules.append(Rule())
    }
    
    func addNewVariable() {
        self.variables.append(Variable())
    }
}

class LSystemManager {
    var system: LSystem = LSystem()
}
