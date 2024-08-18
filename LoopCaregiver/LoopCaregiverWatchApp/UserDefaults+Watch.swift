//
//  UserDefaults+Watch.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/24/23.
//

import Foundation

public extension UserDefaults {
    @objc dynamic var lastPhoneDebugMessage: String? {
        guard let message = object(forKey: "lastPhoneDebugMessage") as? String else {
            return nil
        }

        return message
    }

    @objc
    func updateLastPhoneDebugMessage(_ message: String) {
        setValue(message, forKey: "lastPhoneDebugMessage")
    }
}
