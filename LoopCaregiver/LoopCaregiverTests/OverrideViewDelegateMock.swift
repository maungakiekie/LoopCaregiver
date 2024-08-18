//
//  OverrideViewDelegateMock.swift
//  LoopCaregiverTests
//
//  Created by Bill Gestrich on 4/15/24.
//

import Foundation
@testable import LoopCaregiver
import NightscoutKit

class OverrideViewDelegateMock: OverrideViewDelegate {
    var receivedOverrideRequests = [(overrideName: String, durationTime: TimeInterval)]()
    var mockOverrideState: MockOverrideStateResponse
    var mockDeliveryError: Error?

    internal init(
        receivedOverrideRequests: [(overrideName: String, durationTime: TimeInterval)] = [(overrideName: String, durationTime: TimeInterval)](),
        mockState: OverrideViewDelegateMock.MockOverrideStateResponse,
        mockDeliveryError: Error? = nil
    ) {
        self.receivedOverrideRequests = receivedOverrideRequests
        self.mockOverrideState = mockState
        self.mockDeliveryError = mockDeliveryError
    }

    func overrideState() async throws -> OverrideState {
        switch mockOverrideState {
        case .error(let error):
            throw error
        case .overrideState(let state):
            return state
        }
    }

    func startOverride(overrideName: String, durationTime: TimeInterval) async throws {
        // throw OverrideViewPreviewMockError.NetworkError //Testing
        // guard let preset = presets.first(where: {$0.name == overrideName}) else {return}
        receivedOverrideRequests.append((overrideName: overrideName, durationTime: durationTime))
        if let mockDeliveryError {
            throw mockDeliveryError
        }
    }

    func cancelOverride() async throws {
    }

    static var mockOverrides: [NightscoutKit.TemporaryScheduleOverride] {
        return [
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏃",
                name: "Running"
            ),
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏊",
                name: "Swimming"
            )
        ]
    }

    enum MockError: LocalizedError {
        case networkError

        var errorDescription: String? {
            switch self {
            case .networkError:
                return "Connect to the network"
            }
        }
    }

    enum MockOverrideStateResponse {
        case error(Error)
        case overrideState(OverrideState)
    }
}
