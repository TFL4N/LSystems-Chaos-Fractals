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

class LSystemManager {
    var axiom = Axiom()
    var rules: [Rule] = []
    
    func addNewRule() {
        self.rules.append(Rule())
    }
}
