//
//  AttractorMainViewController.swift
//  L-Systems
//
//  Created by Spizzace on 5/23/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class AttractorMainViewController: NSViewController, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {

    // MARK: ivars
    var document: AttractorDocument? {
        return self.view.window?.windowController?.document as? AttractorDocument
    }
    
    var attractor: Attractor! {
        return self.document?.attractor
    }
    
    @IBOutlet var parametersTableView: NSTableView!
    @IBOutlet var showGraphicsButton: NSButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.parametersTableView.delegate = self
        self.parametersTableView.dataSource = self
        self.parametersTableView.usesAutomaticRowHeights = true
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.parametersTableView.reloadData()
    }
    
    // MARK: TableView DataSource
    private enum CellID {
        static let ParameterName = NSUserInterfaceItemIdentifier(rawValue: "parameter_name")
        static let ParameterValue = NSUserInterfaceItemIdentifier(rawValue: "parameter_value")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.attractor?.parameters.count ?? 0
    }
    
    // MARK: TableView Delegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cell: NSTableCellView? = nil
        
        if tableColumn == self.parametersTableView.tableColumns[0] {
            // create cell
            cell = tableView.makeView(withIdentifier: CellID.ParameterName, owner: nil) as? TextFieldCellView
            if cell == nil {
                cell = TextFieldCellView()
                cell!.identifier = CellID.ParameterName
            }
            
            // fill with data
            let param = self.attractor.parameters[row]
            let param_cell = cell as! TextFieldCellView
            param_cell.mainTextField.isEditable = false
            param_cell.mainTextField.stringValue = param.name
        } else if tableColumn == self.parametersTableView.tableColumns[1] {
            // create cell
            cell = tableView.makeView(withIdentifier: CellID.ParameterName, owner: nil) as? TextFieldCellView
            if cell == nil {
                cell = TextFieldCellView()
                cell!.identifier = CellID.ParameterValue
            }
            
            // fill with data
            let param = self.attractor.parameters[row]
            let param_cell = cell as! TextFieldCellView
            param_cell.mainTextField.stringValue = param.value!.stringValue ?? ""
            param_cell.handler = { (p_cell) in
                param.value!.value = p_cell.mainTextField.stringValue
            }
        }
        
        return cell
    }
    
    // MARK: - Button Handlers
    @IBAction func handleShowGraphicsPress(_: Any?) {
        self.document?.showGraphicsWindowController()
    }
}
