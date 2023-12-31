//
//  AttractorMainViewController.swift
//  L-Systems
//
//  Created by Spizzace on 5/23/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class AttractorDocumentViewController: NSViewController {
    var document: AttractorDocument? {
        return self.view.window?.windowController?.document as? AttractorDocument
    }
    
    var attractor_manager: AttractorManager! {
        return self.document?.attractor_manager
    }
}

class AttractorMainViewController: AttractorDocumentViewController, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {

    // MARK: ivars
    @IBOutlet var parametersTableView: NSTableView!
    @IBOutlet var showGraphicsButton: NSButton!
    
    @IBOutlet var bgColorWell: ColorWell!
    @IBOutlet var baseColorWell: ColorWell!
    @IBOutlet var mainGradientColorWell: GradientColorWell!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.parametersTableView.delegate = self
        self.parametersTableView.dataSource = self
        self.parametersTableView.usesAutomaticRowHeights = true
        
        self.bgColorWell.didSelectColor = { (color) in
            self.attractor_manager.attractor.coloring_info.bgColor = color
        }
        
        self.baseColorWell.didSelectColor = { (color) in
            self.attractor_manager.attractor.coloring_info.baseColor = color
        }
        
        let click_gesture = NSClickGestureRecognizer(target: self, action: #selector(handleMainColorClick(_:)))
        self.mainGradientColorWell.addGestureRecognizer(click_gesture)
    }
    
    private var needsBindings = true
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if self.needsBindings {
            self.needsBindings = false
            
            self.attractor_manager.attractor.coloring_info.addObserver(self, forKeyPath: "didChange", options: [.initial, .new], context: nil)
        }
        
        self.parametersTableView.reloadData()
    }
    
    deinit {
        self.attractor_manager?.attractor.coloring_info.removeObserver(self, forKeyPath: "didChange", context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "didChange" {
            self.mainGradientColorWell.update(withGradientColor: self.attractor_manager.attractor.coloring_info.gradientColor ?? GradientColor())
        }
    }
    
    // MARK: TableView DataSource
    private enum CellID {
        static let ParameterName = NSUserInterfaceItemIdentifier(rawValue: "parameter_name")
        static let ParameterValue = NSUserInterfaceItemIdentifier(rawValue: "parameter_value")
        static let ParameterAnimation = NSUserInterfaceItemIdentifier(rawValue: "parameter_animation")
        static let ParameterUseAnimation = NSUserInterfaceItemIdentifier(rawValue: "parameter_use_animation")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.attractor_manager?.attractor.parameters.count ?? 0
    }
    
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
            let param = self.attractor_manager.attractor.parameters[row]
            let param_cell = cell as! TextFieldCellView
            param_cell.mainTextField.isEditable = false
            param_cell.mainTextField.stringValue = param.name
        } else if tableColumn == self.parametersTableView.tableColumns[1] {
            // create cell
            cell = tableView.makeView(withIdentifier: CellID.ParameterValue, owner: nil) as? TextFieldCellView
            if cell == nil {
                cell = ValueSliderCellView()
                cell!.identifier = CellID.ParameterValue
            }
            
            // fill with data
            let value = self.attractor_manager.attractor.parameters[row].value
            let value_cell = cell as! ValueSliderCellView
            value_cell.value = value
            
            if let value = value {
                switch value.type {
                case .float:
                    value_cell.valueSlider.multiplier = IncrementalSlider.floatValueMultiplier
                case .integer:
                    value_cell.valueSlider.multiplier = IncrementalSlider.integerValueMultiplier
                }
            }
        } else if tableColumn == self.parametersTableView.tableColumns[2] {
            // create cell
            cell = tableView.makeView(withIdentifier: CellID.ParameterUseAnimation, owner: nil) as? NSTableCellView
            
            if cell == nil {
                cell = ButtonTableCellView()
                cell!.identifier = CellID.ParameterAnimation
            }
            
            // fill data
            let button_cell = cell as! ButtonTableCellView
            button_cell.button.title = "Animation"
            button_cell.handler = { (_) in
                self.document?.showAnimationInfo(forParameter: self.attractor_manager.attractor.parameters[row])
            }
        } else if tableColumn == self.parametersTableView.tableColumns[3] {
            // create cell
            cell = tableView.makeView(withIdentifier: CellID.ParameterAnimation, owner: nil) as? NSTableCellView
            
            if cell == nil {
                let new_cell = ButtonTableCellView()
                new_cell.identifier = CellID.ParameterUseAnimation
                new_cell.button.setButtonType(.switch)
                new_cell.button.title = "Use animations"
                
                cell = new_cell
            }
            
            // fill data
            let parameter = self.attractor_manager.attractor.parameters[row]
            let button_cell = cell as! ButtonTableCellView
            button_cell.button.integerValue = NSNumber(value: parameter.uses_animation).intValue
            button_cell.handler = { (view) in
                parameter.uses_animation = NSNumber(value: view.button.integerValue).boolValue
            }
        }
        
        return cell
    }
    
    // MARK: - Button Handlers
    @IBAction func handleShowGraphicsPress(_: Any?) {
        self.document?.showGraphicsWindowController()
    }
    
    @objc func handleMainColorClick(_: NSClickGestureRecognizer) {
        self.document?.showColoringInfo()
    }
}
