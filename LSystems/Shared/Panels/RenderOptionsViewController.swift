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
    @IBOutlet var pointSizeTextField: NSTextField!
    @IBOutlet var renderRefreshButton: NSButton!
    
    @IBOutlet var cameraViewingModeButton: NSPopUpButton!
    @IBOutlet var cameraProjectionModeButton: NSPopUpButton!
    @IBOutlet var cameraTranslationTextField: NSTextField!
    @IBOutlet var cameraRotationTextField: NSTextField!
    @IBOutlet var cameraScaleTextField: NSTextField!
    
    let camera_viewing_mode_controller = NSArrayController(content: [
        CameraViewingMode.free_floating.rawValue,
        CameraViewingMode.fixed_towards_origin.rawValue
        ])
    
    let camera_projection_mode_controller = NSArrayController(content: [
        CameraProjectionMode.orthogonal.rawValue,
        CameraProjectionMode.perspective.rawValue
        ])
    
    let render_mode_controller = NSArrayController(content: [
        RenderMode.live.rawValue,
        RenderMode.static.rawValue
        ])
    
    private var needsBindings = true
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if self.needsBindings {
            self.needsBindings = false
            
            let renderer = self.document!.graphics_view_cltr.renderer!
            
            // Camera
            //////////////
            // Viewing Mode
            self.cameraViewingModeButton
                .bind(.content,
                      to: self.camera_viewing_mode_controller,
                      withKeyPath: "arrangedObjects",
                      options: nil)
            self.cameraViewingModeButton
                .bind(.selectedObject,
                      to: renderer,
                      withKeyPath: "camera_viewing_mode_raw",
                      options: nil)
            
            // Projection
            self.cameraProjectionModeButton
                .bind(.content,
                      to: self.camera_projection_mode_controller,
                      withKeyPath: "arrangedObjects",
                      options: nil)
            self.cameraProjectionModeButton
                .bind(.selectedObject,
                  to: renderer,
                  withKeyPath: "camera_projection_mode_raw",
                  options: nil)
            
            // transformations
            self.cameraRotationTextField
                .bind(.value,
                      to: renderer,
                      withKeyPath: "rotation",
                      options: nil)
            
            self.cameraScaleTextField
                .bind(.value,
                      to: renderer,
                      withKeyPath: "scale",
                      options: nil)
            
//            self.cameraTranslationTextField
//                .bind(.value,
//                      to: self,
//                      withKeyPath: "foo",
//                      options: nil)
            
            // Rendering
            /////////////
            self.renderModeButton
                .bind(.content,
                      to: self.render_mode_controller,
                      withKeyPath: "arrangedObjects",
                      options: nil)
            self.renderModeButton
                .bind(.selectedObject,
                      to: self.document!.graphics_view_cltr!,
                      withKeyPath: "render_mode_raw",
                      options: nil)
            
            self.pointSizeTextField
            .bind(.value,
                  to: renderer,
                  withKeyPath: "pointSize",
                  options: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pointSizeTextField.formatter = AttractorRenderer.pointSizeFormatter()
        self.cameraTranslationTextField.formatter = NumberFormatter.buildFloatFormatter(min: nil, max: nil)
        self.cameraRotationTextField.formatter = NumberFormatter.buildFloatFormatter(min: nil, max: nil)
        self.cameraScaleTextField.formatter = NumberFormatter.buildFloatFormatter(min: nil, max: nil)
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
        self.document?.graphics_view_cltr?.handleRefreshPress()
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
