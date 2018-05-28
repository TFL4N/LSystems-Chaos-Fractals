//
//  ValueSlider.swift
//  L-Systems
//
//  Created by Spizzace on 5/27/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class ValueSlider: NSSlider {

    var multiplier: Float = 0.01
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
    
    var last_message_time: TimeInterval = 0.0
    let message_rate: TimeInterval = 0.1
    @objc func handleSliderUpdate(_ sender: NSSlider) {
        // filter messages
        let current_time = Date.timeIntervalSinceReferenceDate
        if current_time - self.last_message_time > self.message_rate {
            self.last_message_time = current_time
            
            // set value
            guard let val = self.value else { return }
            switch val.type {
            case .float:
                val.floatValue! += self.multiplier * self.floatValue
            case .integer:
                val.integerValue! += Int(self.multiplier * self.floatValue)
            }
        }
    }
}
