//
//  GradientColorViewController.swift
//  L-Systems
//
//  Created by Spizzace on 6/2/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class GradientColorSettingsViewController: NSViewController, ColoringInfoSettingsProtocol, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet var color_list_table_view: NSTableView!
    @IBOutlet var gradient_color_well: GradientColorWell!
    
    var coloring_info: ColoringInfo {
        return (self.parent as! ColoringInfoSettingsProtocol).coloring_info
    }
    
    var gradient_color: GradientColor {
        let info = self.coloring_info
        if info.gradientColor == nil {
            info.gradientColor = GradientColor()
        }
        
        info.gradientColor?.didChangeHandler = self.handleColorDidChange(_:)
        
        return info.gradientColor!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private var needsBindings = true
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if self.needsBindings {
            self.needsBindings = false
            self.color_list_table_view.delegate = self
            self.color_list_table_view.dataSource = self
            self.color_list_table_view.usesAutomaticRowHeights = true
        }
        
        self.handleColorDidChange(self.gradient_color)
    }
    
    private func handleColorDidChange(_ color: GradientColor) {
        self.color_list_table_view.reloadData()
        self.gradient_color_well.update(withGradientColor: self.gradient_color)
    }
    
    // MARK: - TableView
    private enum CellID {
        static let ColorCell = NSUserInterfaceItemIdentifier(rawValue: "color_cell")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.gradient_color.colors.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell: GradientColorItemCellView = tableView.makeView(withIdentifier: CellID.ColorCell, owner: nil) as! GradientColorItemCellView
        
        cell.gradient_color_item = self.gradient_color.colors[row]
        
        return cell
    }
    
    // MARK: Actions
    @IBAction func handleAddPress(_: Any?) {
        self.gradient_color.addColor(CGColor.white, atPosition: 0.0)
        self.color_list_table_view.reloadData()
    }
    
    @IBAction func handleDeletePress(_: Any?) {
        let selection = self.color_list_table_view.selectedRow
        if selection >= 0 {
            self.gradient_color.removeColor(atIndex: selection)
        }
    }
}
