//
//  FilePathTextField.swift
//  L-Systems
//
//  Created by Spizzace on 6/8/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class FilePathTextField: NSTextField {

    var fileURL: URL? {
        get {
            return URL(fileURLWithPath: self.stringValue)
        }
        set {
            self.stringValue = newValue?.path ?? ""
        }
    }
    
    var defaultFileURL: URL? = nil
    
    var allowedFileTypes: [String]? = nil
    var allowsOtherFileTypes: Bool = false
    var isExtensionHidden: Bool = false
    
    var handleDidSelectFileURL: ((FilePathTextField, URL?)->())?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleVideoOutputPathClick(_:))))
    }
    
    @objc func handleVideoOutputPathClick(_ gesture: NSClickGestureRecognizer) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = self.allowedFileTypes
        panel.allowsOtherFileTypes = self.allowsOtherFileTypes
        panel.isExtensionHidden = self.isExtensionHidden
        panel.directoryURL = self.fileURL?.deletingLastPathComponent() ?? self.defaultFileURL ?? FileManager.default.homeDirectoryForCurrentUser
        
        panel.begin { (response) in
            if response == NSApplication.ModalResponse.OK {
                self.fileURL = panel.url
                self.handleDidSelectFileURL?(self, panel.url)
            }
        }
    }
}
