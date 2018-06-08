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
        return URL(fileURLWithPath: self.stringValue)
    }
    
    var defaultFileURL: URL? = nil
    
    var allowedFileTypes: [String]? = nil
    var allowsOtherFileTypes: Bool = false
    var isExtensionHidden: Bool = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func commonInit() {
        self.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleVideoOutputPathClick(_:))))
    }
    
    @objc func handleVideoOutputPathClick(_ gesture: NSClickGestureRecognizer) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = self.allowedFileTypes
        panel.allowsOtherFileTypes = self.allowsOtherFileTypes
        panel.isExtensionHidden = self.isExtensionHidden
        panel.directoryURL = self.fileURL?.deletingLastPathComponent() ?? self.defaultFileURL
        
        panel.begin { (response) in
            if response == NSApplication.ModalResponse.OK {
                self.stringValue = panel.url?.path ?? self.defaultFileURL?.path ?? ""
            }
        }
    }
}
