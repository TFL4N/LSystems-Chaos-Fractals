//
//  ImageInfoPanelViewController.swift
//  L-Systems
//
//  Created by Spizzace on 5/25/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class RenderOptionsViewController: AttractorDocumentViewController, NSTextFieldDelegate {

    @IBOutlet var renderModeButton: NSPopUpButton!
    @IBOutlet var renderRefreshButton: NSButton!
    
    @IBOutlet var cameraViewingModeButton: NSPopUpButton!
    @IBOutlet var cameraProjectionModeButton: NSPopUpButton!
    @IBOutlet var cameraTranslationTextField: NSTextField!
    @IBOutlet var cameraRotationTextField: NSTextField!
    @IBOutlet var cameraScaleTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Render Settings
        self.renderModeButton.addItems(withTitles:[
            RenderMode.live.rawValue,
            RenderMode.static.rawValue
            ])
        
        // Camera Settings
        self.cameraViewingModeButton.addItems(withTitles:[
            CameraViewingMode.free_floating.rawValue,
            CameraViewingMode.fixed_towards_origin.rawValue
            ])
        self.cameraProjectionModeButton.addItems(withTitles:[
            CameraProjectionMode.perspective.rawValue,
            CameraProjectionMode.orthogonal.rawValue
            ])
    }
   
    override func controlTextDidEndEditing(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        
        switch textView {
        case self.cameraTranslationTextField:
            break
        case self.cameraRotationTextField:
            break
        case self.cameraScaleTextField:
            break
        default:
            break
        }
    }
    
    // MARK: Render Settings
    @IBAction func handleRenderModeSelection(_ sender: AnyObject) {
        guard let selected_title = (sender as! NSPopUpButton).selectedItem?.title,
            let mode = RenderMode(rawValue: selected_title)
        else {
            return
        }
        
        
    }
    
    @IBAction func handleRenderRefreshPress(_ sender: AnyObject) {
        
    }
    
    // MARK: Camera Settings
    @IBAction func handleCameraViewingModeSelection(_ sender: AnyObject) {
        guard let selected_title = (sender as! NSPopUpButton).selectedItem?.title,
            let mode = CameraViewingMode(rawValue: selected_title)
            else {
                return
        }
        
        
    }
    
    @IBAction func handleCameraProjectionModeSelection(_ sender: AnyObject) {
        guard let selected_title = (sender as! NSPopUpButton).selectedItem?.title,
            let mode = CameraProjectionMode(rawValue: selected_title)
            else {
                return
        }
        
        
    }
}
