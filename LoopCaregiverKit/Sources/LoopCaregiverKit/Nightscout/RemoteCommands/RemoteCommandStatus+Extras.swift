//
//  RemoteCommandStatus.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/31/22.
//

import LoopKit
import NightscoutKit

extension RemoteCommandStatus {
    func toNSRemoteCommandStatus() -> NSRemoteCommandStatus {
        return NSRemoteCommandStatus(state: state.toNSRemoteCommandState(), message: message)
    }
}

extension RemoteCommandStatus.RemoteComandState {
    func toNSRemoteCommandState() -> NSRemoteCommandStatus.NSRemoteComandState {
        switch self {
        case .error:
            return .Error
        case .success:
            return .Success
        case .inProgress:
            return .InProgress
        case .pending:
            return .Pending
        }
    }
}
