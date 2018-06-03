//
//  ColoringInfoPanelViewController.swift
//  L-Systems
//
//  Created by Spizzace on 6/2/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class ColoringInfoPanelViewController: AttractorDocumentViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet var color_list_table_view: NSTableView!
    @IBOutlet var gradient_color_well: GradientColorWell!
    
    var gradient_color = GradientColor() {
        didSet {
            self.gradient_color.didChangeHandler = self.handleColorDidChange(_:)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.color_list_table_view.delegate = self
        self.color_list_table_view.dataSource = self
        self.color_list_table_view.usesAutomaticRowHeights = true
        
        self.gradient_color.didChangeHandler = self.handleColorDidChange(_:)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.color_list_table_view.reloadData()
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
