//
//  RemoteCommand.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 2/25/23.
//

import Foundation

public struct RemoteCommand: Equatable {
    public let id: String
    public let action: Action
    public let status: RemoteCommandStatus
    public let createdDate: Date

    public init(id: String, action: Action, status: RemoteCommandStatus, createdDate: Date) {
        self.id = id
        self.action = action
        self.status = status
        self.createdDate = createdDate
    }
}
