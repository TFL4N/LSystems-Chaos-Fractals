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
    var document: Document? {
        return view.window?.windowController?.document as? Document
    }
    
    var l_system_manager: LSystemManager? {
        return self.document?.l_system_manager
    }
    
    @IBOutlet weak var axiomTextField: NSTextField!;
    @IBOutlet weak var iterationsTextField: NSTextField!;
    @IBOutlet weak var iterationsStepper: NSStepper!;
    
    @IBOutlet weak var variableTableView: NSTableView!;
    @IBOutlet weak var ruleTableView: NSTableView!;
    
    @IBOutlet weak var outputStringTextView: NSTextView!;
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleVariableDidChange(_:)), name: Notifications.VariableTypeDidChangeNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // axiom text field
        self.axiomTextField.delegate = self
        
        // iterations text field
        self.iterationsTextField.delegate = self
        
        // variables table view
        self.variableTableView.dataSource = self
        self.variableTableView.delegate = self
        self.variableTableView.usesAutomaticRowHeights = true
        
        
        // rule table view
        self.ruleTableView.dataSource = self
        self.ruleTableView.delegate = self
        self.ruleTableView.usesAutomaticRowHeights = true
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.refreshStepperView()
        
        self.ruleTableView.reloadData()
        self.variableTableView.reloadData()
        
        self.axiomTextField.stringValue = self.l_system_manager?.system.axiom.value ?? ""
    }
    
    func refreshStepperView() {
        self.iterationsTextField.stringValue = "\(self.l_system_manager?.system.iterations ?? 0)"
        self.iterationsStepper.integerValue = self.l_system_manager?.system.iterations ?? 0
    }
    
    // MARK: Actions
    @IBAction func addRule(_: Any?) {
        self.l_system_manager?.system.addNewRule()
        self.ruleTableView.reloadData()
    }
    
    @IBAction func addVariable(_: Any?) {
        self.l_system_manager?.system.addNewVariable()
        self.variableTableView.reloadData()
    }
    
    @IBAction func handleIterationsStepper(_ sender:Any?) {
        if let stepper = sender as? NSStepper {
            self.l_system_manager?.system.iterations = stepper.integerValue
            self.refreshStepperView()
        }
    }
    
    @IBAction func createString(_: Any?) {
        do {
            self.outputStringTextView.string = try self.l_system_manager!.createLSystemString()
        } catch {
            self.outputStringTextView.string = "\(error)"
        }
    }
    
    // MARK: TextField Delegate
    override func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            if self.axiomTextField.identifier == textField.identifier {
                self.l_system_manager?.system.axiom.value = self.axiomTextField.stringValue
            }
        }
    }
    
    // MARK: TableView DataSource
    private enum CellID {
        static let Rule = NSUserInterfaceItemIdentifier(rawValue: "rule")
        static let TextField = NSUserInterfaceItemIdentifier(rawValue: "textfield")
        static let VariableType = NSUserInterfaceItemIdentifier(rawValue: "variable_type")
        static let VariableName = NSUserInterfaceItemIdentifier(rawValue: "variable_name")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.ruleTableView {
            return self.l_system_manager?.system.rules.count ?? 0
        } else if tableView == self.variableTableView {
            return self.l_system_manager?.system.variables.count ?? 0
        }
        
        return 0
    }

    // MARK: TableView Delegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cell: NSTableCellView? = nil
        
        if tableView == self.ruleTableView {
            // create cell
            cell = tableView.makeView(withIdentifier: CellID.Rule, owner: nil) as? RuleCellView
            if cell == nil {
                cell = RuleCellView()
                cell?.identifier = CellID.Rule
            }
            
            // fill with data
            let rule = self.l_system_manager?.system.rules[row]
            let rule_cell = cell as! RuleCellView
            rule_cell.rule = rule
        } else if tableView == self.variableTableView {
            let variable = self.l_system_manager!.system.variables[row]
            
            if tableColumn == self.variableTableView.tableColumns[0] {
                // create cell
                cell = tableView.makeView(withIdentifier: CellID.VariableName, owner: nil) as? NSTableCellView
                if cell == nil {
                    cell = TextFieldCellView()
                    cell?.identifier = CellID.VariableName
                }
                
                // fill with data
                let temp = cell as! TextFieldCellView
                temp.mainTextField.stringValue = variable.name
                temp.handler = { (text_cell) in
                    variable.name = text_cell.mainTextField.stringValue
                    self.ruleTableView.reloadData()
                }
            } else if tableColumn == self.variableTableView.tableColumns[1] {
                // create cell
                cell = tableView.makeView(withIdentifier: CellID.VariableType, owner: nil) as? NSTableCellView
                if cell == nil {
                    cell = VariableTypeCellView()
                    cell?.identifier = CellID.VariableType
                }
                
                // fill with data
                let temp = cell as! VariableTypeCellView
                temp.variable = variable
            }
        }
        
        return cell
    }
    
    // MARK: Notifications Handlers
    @objc private func handleVariableDidChange(_ notification: Notification) {
        self.ruleTableView.reloadData()
    }
}
