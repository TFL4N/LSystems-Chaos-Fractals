//
//  ValueSlider.swift
//  L-Systems
//
//  Created by Spizzace on 5/27/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class IncrementalSlider: NSSlider {
    static let integerValueMultiplier: Float = 5
    static let floatValueMultiplier: Float = 0.01
    
    private var last_message_time: TimeInterval = 0.0
    var message_rate: TimeInterval = 0.1
    
    var multiplier: Float = 0.01
    var handler: ((Float)->())?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    
        self.commonInit()
    }

    private func commonInit() {
        self.sliderType = .linear
        self.isVertical = false
        self.maxValue = 1.0
        self.minValue = -1.0
        self.trackFillColor = NSColor.red
        self.isContinuous = true
        self.floatValue = 0
        
        self.target = self
        self.action = #selector(handleSliderUpdate(_:))
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        self.floatValue = 0
    }
    
    @objc func handleSliderUpdate(_ sender: NSSlider) {
        // filter messages
        let current_time = Date.timeIntervalSinceReferenceDate
        if current_time - self.last_message_time > self.message_rate {
            self.last_message_time = current_time
            
           self.handler?(self.multiplier * self.floatValue)
        }
    }
}

class ValueSlider: IncrementalSlider {
    var value: Value?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.commonInit()
    }
    
    private func commonInit() {
        self.handler = { (inc) in
            // set value
            guard let val = self.value else { return }
            switch val.type {
            case .float:
                val.floatValue! += inc
            case .integer:
                val.integerValue! += Int(inc)
            }
        }
    }
}
