//
//  NibLoadable.swift
//  L-Systems
//
//  Created by Spizzace on 6/8/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import AppKit

public protocol NibLoadable {
    static var nibName: NSNib.Name { get }
}

public extension NibLoadable where Self: NSView {
    
    public static var nibName: NSNib.Name {
        return NSNib.Name(String(describing: Self.self)) // defaults to the name of the class implementing this protocol.
    }
    
    public static var nib: NSNib? {
        let bundle = Bundle(for: Self.self)
        return NSNib(nibNamed: Self.nibName, bundle: bundle)
    }
    
    public static func awakeFromNib(originalInstance: NSView?) -> Self {
        guard let nib = Self.nib else {
            fatalError("Error loading \(self) from nib -- No nib named: \(Self.nibName)")
        }
        
        var top_level_objects: NSArray?
        guard nib.instantiate(withOwner: self, topLevelObjects: &top_level_objects),
            let newView = top_level_objects?.first(where: { $0 is NSView }) as? NSView else {
                fatalError("Error loading \(self) from nib")
                
        }
        
        if let originalInstance = originalInstance {
        for constraint in originalInstance.constraints {
            if constraint.secondItem != nil {
                newView.addConstraint(NSLayoutConstraint(item: newView, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: newView, attribute: constraint.secondAttribute, multiplier: constraint.multiplier, constant: constraint.constant))
            } else {
                newView.addConstraint(NSLayoutConstraint(item: newView, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: constraint.constant))
            }
        }
        }
        
        return newView as! Self
    }
}
