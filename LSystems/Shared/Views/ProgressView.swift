//
//  ProgressView.swift
//  L-Systems
//
//  Created by Spizzace on 6/8/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class Label: NSTextField {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.isEditable = false
        self.isBordered = false
        self.isBezeled = false
        self.drawsBackground = false
    }
}

class ProgressView: NSBox {
    
    var progressIndicator: NSProgressIndicator!
    var progressLabel: Label!
    var progressElapsedLabel: Label!
    var progressRemainingLabel: Label!
    
    var timeLabelFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .dropLeading
        
        return formatter
        }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.commonInit()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.commonInit()
    }
    
    private func commonInit() {
        let content = NSView(frame: NSRect.zero)
        content.translatesAutoresizingMaskIntoConstraints = false
        
        self.progressIndicator = NSProgressIndicator(frame: NSRect.zero)
        self.progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.progressIndicator.maxValue = 1.0
        self.progressIndicator.minValue = 0.0
        
        self.progressLabel = Label(frame: NSRect.zero)
        self.progressLabel.translatesAutoresizingMaskIntoConstraints = false
        self.progressLabel.formatter = NumberFormatter.buildPercentFormatter(fractionDigits: 2)
        
        self.progressElapsedLabel = Label(frame: NSRect.zero)
        self.progressElapsedLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.progressRemainingLabel = Label(frame: NSRect.zero)
        self.progressRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        self.progressRemainingLabel.alignment = .right
        
        let views: [String:Any] = [
            "indicator": self.progressIndicator,
            "percent": self.progressLabel,
            "elapsed": self.progressElapsedLabel,
            "remaining": self.progressRemainingLabel
        ]
        
        for (_,v) in views {
            content.addSubview(v as! NSView)
        }
        self.addSubview(content)
        
        content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[indicator(200)]-[percent(68)]-20-|", options: [.alignAllCenterY], metrics: nil, views: views))
        content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[elapsed]-[remaining]-20-|", options: [.alignAllCenterY], metrics: nil, views: views))
        content.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[indicator]-[elapsed]-10-|", options: [], metrics: nil, views: views))
        
        self.contentView = content
    }
    
    func setProgress(_ value: Double?) {
        self.progressIndicator.doubleValue = value ?? 0.0
        self.progressIndicator.doubleValue = value ?? 0.0
    }
    
    func setElapsedTime(_ elapsed_time: Double?) {
        if let value = elapsed_time,
            let str = self.timeLabelFormatter.string(from: value) {
            self.progressElapsedLabel.stringValue = str
        } else {
            self.progressElapsedLabel.stringValue = ""
        }
    }
    
    func setRemaingTime(_ remaining_time: Double?) {
        if let value = remaining_time,
            let str = self.timeLabelFormatter.string(from: value) {
            self.progressRemainingLabel.stringValue = str
        } else {
            self.progressRemainingLabel.stringValue = ""
        }
    }
}
