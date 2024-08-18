//
//  Bundle+Extensions.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 6/2/23.
//

import Foundation

public extension Bundle {
    var bundleDisplayName: String {
        // swiftlint:disable force_cast
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
        // swiftlint:enable force_cast
    }

    var appGroupSuiteName: String? {
        return object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
    }
}
