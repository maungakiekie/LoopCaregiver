//
//  OverrideAction.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/25/22.
//

import Foundation

public struct OverrideAction: Codable, Equatable {
    public let name: String
    public let durationTime: TimeInterval?
    public let remoteAddress: String

    public init(name: String, durationTime: TimeInterval? = nil, remoteAddress: String) {
        self.name = name
        self.durationTime = durationTime
        self.remoteAddress = remoteAddress
    }
}
