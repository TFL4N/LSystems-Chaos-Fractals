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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.color_list_table_view.delegate = self
        self.color_list_table_view.dataSource = self
        self.color_list_table_view.usesAutomaticRowHeights = true
    }
    
    // MARK: - TableView
    private enum CellID {
        static let ColorCell = NSUserInterfaceItemIdentifier(rawValue: "color_cell")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cell: NSTableCellView? = nil
        
        cell = tableView.makeView(withIdentifier: CellID.ColorCell, owner: nil) as? ColorLinearCellView
        
        return cell
    }
}
