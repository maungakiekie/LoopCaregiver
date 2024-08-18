//
//  AutobolusAction.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 3/19/23.
//

import Foundation

public struct AutobolusAction: Codable, Equatable {
    public let active: Bool

    public init(active: Bool) {
        self.active = active
    }
}
