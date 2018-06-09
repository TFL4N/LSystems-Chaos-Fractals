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
        let font = NSFont.systemFont(ofSize: 16)
        
        self.progressIndicator = NSProgressIndicator(frame: NSRect.zero)
        self.progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.progressIndicator.isIndeterminate = false
        self.progressIndicator.maxValue = 1.0
        self.progressIndicator.minValue = 0.0
        
        self.progressLabel = Label(frame: NSRect.zero)
        self.progressLabel.translatesAutoresizingMaskIntoConstraints = false
        self.progressLabel.formatter = NumberFormatter.buildPercentFormatter(fractionDigits: 2)
        self.progressLabel.alignment = .right
        self.progressLabel.font = font
        
        self.progressElapsedLabel = Label(frame: NSRect.zero)
        self.progressElapsedLabel.translatesAutoresizingMaskIntoConstraints = false
        self.progressElapsedLabel.font = font
        
        self.progressRemainingLabel = Label(frame: NSRect.zero)
        self.progressRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        self.progressRemainingLabel.alignment = .right
        self.progressRemainingLabel.font = font
        
        let views: [String:Any] = [
            "indicator": self.progressIndicator,
            "percent": self.progressLabel,
            "elapsed": self.progressElapsedLabel,
            "remaining": self.progressRemainingLabel
        ]
        
        self.contentView = NSView(frame: NSRect.zero)
        self.boxType = .primary
        
        for (_,v) in views {
            self.contentView!.addSubview(v as! NSView)
        }
        
        self.contentView!.addConstraints(NSLayoutConstraint
            .constraints(withVisualFormat: "H:|-20-[indicator(200)]-[percent(68)]-20-|", options: [.alignAllCenterY], metrics: nil, views: views))
        self.contentView!.addConstraints(NSLayoutConstraint
            .constraints(withVisualFormat: "H:|-20-[elapsed]-[remaining]-20-|", options: [.alignAllCenterY], metrics: nil, views: views))
        self.contentView!.addConstraints(NSLayoutConstraint
            .constraints(withVisualFormat: "V:|-10-[indicator]-[elapsed]-10-|", options: [], metrics: nil, views: views))
        
    }
    
    func setProgess(_ value: Double?, elapsedTime: TimeInterval?, remainingTime: TimeInterval?) {
        self.setProgress(value)
        self.setElapsedTime(elapsedTime)
        self.setRemainingTime(remainingTime)
    }
    
    func setProgress(_ value: Double?) {
        self.progressIndicator.doubleValue = value ?? 0.0
        self.progressLabel.doubleValue = value ?? 0.0
    }
    
    func setElapsedTime(_ elapsed_time: TimeInterval?) {
        if let value = elapsed_time,
            let str = self.timeLabelFormatter.string(from: value) {
            self.progressElapsedLabel.stringValue = str
        } else {
            self.progressElapsedLabel.stringValue = ""
        }
    }
    
    func setRemainingTime(_ remaining_time: TimeInterval?) {
        if let value = remaining_time,
            value > 0.0,
            let str = self.timeLabelFormatter.string(from: value) {
            self.progressRemainingLabel.stringValue = str
        } else {
            self.progressRemainingLabel.stringValue = ""
        }
    }
}
