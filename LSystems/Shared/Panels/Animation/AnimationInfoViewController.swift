//
//  AnimationInfoViewController.swift
//  L-Systems
//
//  Created by Spizzace on 6/10/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class AnimationInfoViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet var animationTableView: NSTableView!
    
    var valueType: ValueType = .float
    var animationSequence: AnimationSequence? {
        didSet {
            self.animationTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pasteboard_types = [NSPasteboard.PasteboardType(rawValue: "public.data")]
        self.animationTableView.registerForDraggedTypes(pasteboard_types)
        self.animationTableView.delegate = self
        self.animationTableView.dataSource = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.animationTableView.reloadData()
    }
    
    // MARK: - TableView Datasource
    private enum CellID {
        static let KeyFrameCell = NSUserInterfaceItemIdentifier(rawValue: "keyframe_cell")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.animationSequence?.key_frames.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell: AnimationKeyFrameTableCellView = tableView.makeView(withIdentifier: CellID.KeyFrameCell, owner: nil) as! AnimationKeyFrameTableCellView
        
        cell.keyframe = self.animationSequence?.key_frames[row]
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let item = NSPasteboardItem()
        item.setData(NSKeyedArchiver.archivedData(withRootObject: rowIndexes),
                     forType: NSPasteboard.PasteboardType(rawValue: "public.data"))
        
        pboard.writeObjects([item])
        
        return true
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard let source = info.draggingSource() as? NSTableView,
            source === self.animationTableView
            else { return [] }
        
        if dropOperation == .above {
            return .move
        }
        return []
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let pb = info.draggingPasteboard()
        let type = NSPasteboard.PasteboardType(rawValue: "public.data")
        if let itemData = pb.pasteboardItems?.first?.data(forType: type),
            let indexes = NSKeyedUnarchiver.unarchiveObject(with: itemData) as? IndexSet
        {
            self.animationSequence?.key_frames.move(with: indexes, to: row)
            
            let targetIndex = row - (indexes.filter{ $0 < row }.count)
            tableView.selectRowIndexes(IndexSet(targetIndex..<targetIndex+indexes.count), byExtendingSelection: false)
            return true
        }
        
        return false
    }
    
    // MARK: - Buttons
    @IBAction func handleAddFramePress(_: Any?) {
        let key_frame = KeyFrame(value: Value(type: self.valueType, value: nil),
                                 duration: 0)
        self.animationSequence?.key_frames.append(key_frame)
        
        self.animationTableView.reloadData()
    }
    
    @IBAction func handleRemoveFramePress(_: Any?) {
        self.animationSequence?.key_frames.remove(atIndices: self.animationTableView.selectedRowIndexes)
        
        self.animationTableView.reloadData()
    }
}
