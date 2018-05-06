//
//  MainViewController.swift
//  L-Systems
//
//  Created by Spizzace on 3/28/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    // MARK: ivars
    var l_system_manager: LSystemManager = LSystemManager()
    
    @IBOutlet weak var axiomTextField: NSTextField!;
    @IBOutlet weak var ruleTableView: NSTableView!;
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // axiom text field
        self.axiomTextField.delegate = self
        
        // rule table view
        self.ruleTableView.dataSource = self
        self.ruleTableView.delegate = self
        self.ruleTableView.usesAutomaticRowHeights = true
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            if self.axiomTextField.identifier == textField.identifier {
                self.l_system_manager.axiom.value = self.axiomTextField.stringValue
            }
        }
    }
    
    // MARK: Actions
    @IBAction func addRule(_: Any?) {
        print("Add Rule")
        self.l_system_manager.addNewRule()
        self.ruleTableView.reloadData()
        print("Count: \(self.ruleTableView)")
    }
    
    // MARK: TableView DataSource
    private enum CellID {
        static let Rule = NSUserInterfaceItemIdentifier(rawValue: "rule")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.l_system_manager.rules.count
    }

    // MARK: TableView Delegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        // create cell
        var cell: RuleTableCellView! = tableView.makeView(withIdentifier: CellID.Rule, owner: nil) as? RuleTableCellView
        if cell == nil {
            cell = RuleTableCellView()
        }
        
        // fill with data
        let rule = self.l_system_manager.rules[row]
        cell.rule = rule
        
        return cell
    }
}
