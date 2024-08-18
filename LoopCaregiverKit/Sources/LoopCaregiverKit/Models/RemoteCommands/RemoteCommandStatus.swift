//
//  RemoteCommandStatus.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 3/19/23.
//

import Foundation

public struct RemoteCommandStatus: Equatable {
    public let state: RemoteComandState
    public let message: String

    public enum RemoteComandState: Equatable {
        case pending
        case inProgress
        case success
        case error(RemoteCommandStatusError)

        public var title: String {
            switch self {
            case .pending:
                return "Pending"
            case .inProgress:
                return "In-Progress"
            case .success:
                return "Success"
            case .error:
                return "Error"
            }
        }
    }

    public struct RemoteCommandStatusError: LocalizedError, Equatable {
        let message: String

        public var errorDescription: String? {
            return message
        }

        public init(message: String) {
            self.message = message
        }
    }

    public init(state: RemoteCommandStatus.RemoteComandState, message: String) {
        self.state = state
        self.message = message
    }
}
