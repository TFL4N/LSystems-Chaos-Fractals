//
//  NotificationCenter.swift
//  L-Systems
//
//  Created by Spizzace on 5/6/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Cocoa

class Notifications {
    static let VariableTypeDidChangeNotification = Notification.Name("variable_type_did_change")
    static let SaveImagePressNotification = Notification.Name("save_image_press")
    
    
    static func postVariableTypeDidChange(_ variable: Variable) {
        NotificationCenter.default.post(name: VariableTypeDidChangeNotification, object: nil, userInfo: ["variable": variable])
    }
    
    static func postSaveImagePress(info: [AnyHashable:Any]?) {
        NotificationCenter.default.post(name: SaveImagePressNotification,
                                        object: nil,
                                        userInfo: info)
    }
}
