//
//  OverrideCancelAction.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/25/22.
//

import Foundation

public struct OverrideCancelAction: Codable, Equatable {
    let remoteAddress: String

    public init(remoteAddress: String) {
        self.remoteAddress = remoteAddress
    }
}
