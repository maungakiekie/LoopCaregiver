//
//  NSRemoteCommandPayload.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/27/22.
//

import Foundation
import LoopKit
import NightscoutKit

public extension NSRemoteCommandPayload {
    func toRemoteCommand() throws -> RemoteCommand {
        guard let id = _id else {
            throw RemoteCommandPayloadError.missingID
        }

        return RemoteCommand(id: id, action: toRemoteAction(), status: status.toStatus(), createdDate: createdDate)
    }

    func toRemoteAction() -> Action {
        switch action {
        case let .bolus(amountInUnits):
            return .bolusEntry(BolusAction(amountInUnits: amountInUnits))
        case let .carbs(amountInGrams, absorptionTime, startDate):
            return .carbsEntry(CarbAction(amountInGrams: amountInGrams, absorptionTime: absorptionTime, startDate: startDate))
        case let .override(name, durationTime, remoteAddress):
            return .temporaryScheduleOverride(OverrideAction(name: name, durationTime: durationTime, remoteAddress: remoteAddress))
        case let .cancelOverride(remoteAddress):
            return .cancelTemporaryOverride(OverrideCancelAction(remoteAddress: remoteAddress))
        case let .autobolus(active):
            return .autobolus(AutobolusAction(active: active))
        case let .closedLoop(active):
            return .closedLoop(ClosedLoopAction(active: active))
        }
    }
}

extension NSRemoteCommandStatus {
    func toStatus() -> RemoteCommandStatus {
        let commandState: RemoteCommandStatus.RemoteComandState
        switch self.state {
        case .Pending:
            commandState = RemoteCommandStatus.RemoteComandState.pending
        case .InProgress:
            commandState = RemoteCommandStatus.RemoteComandState.inProgress
        case .Success:
            commandState = RemoteCommandStatus.RemoteComandState.success
        case .Error:
            let error = RemoteCommandStatus.RemoteCommandStatusError(message: message)
            commandState = RemoteCommandStatus.RemoteComandState.error(error)
        }
        return RemoteCommandStatus(state: commandState, message: message)
    }
}

enum RemoteCommandPayloadError: LocalizedError {
    case missingID

    var errorDescription: String? {
        switch self {
        case .missingID:
            return "Missing ID"
        }
    }
}
