//
//  RemoteNotification.swift
//  LoopCaregiverKit
//
//  Created by Bill Gestrich on 2/25/23.
//

import Foundation

public protocol RemoteNotification: Codable {
    var id: String {get}
    var expiration: Date? {get}
    var sentAt: Date? {get}
    var remoteAddress: String {get}
    var enteredBy: String? {get}

    func toRemoteAction() -> Action

    static func includedInNotification(_ notification: [String: Any]) -> Bool
}

extension RemoteNotification {
    public var id: String {
        // There is no unique identifier so we use the sent date when available
        guard let sentAt else {
            return UUID().uuidString
        }
        return "\(sentAt.timeIntervalSince1970)"
    }

    init(dictionary: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601DateDecoder)
        self = try jsonDecoder.decode(Self.self, from: data)
    }
}

extension DateFormatter {
    static var iso8601DateDecoder: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // Ex: 2022-12-24T21:34:02.090Z
        return formatter
    }()
}

public extension Dictionary<String, AnyObject> {
    enum RemoteNotificationError: LocalizedError {
        case unhandledNotification([String: AnyObject])

        public var errorDescription: String? {
            switch self {
            case .unhandledNotification(let notification):
                return String(format: NSLocalizedString("Unhandled Notification: %1$@", bundle: .module, comment: "The prefix for the remote unhandled notification error. (1: notification payload)"), notification)
            }
        }
    }

    func toRemoteNotification() throws -> RemoteNotification {
        var notificationType: RemoteNotification.Type
        if BolusRemoteNotification.includedInNotification(self) {
            notificationType = BolusRemoteNotification.self
        } else if CarbRemoteNotification.includedInNotification(self) {
            notificationType = CarbRemoteNotification.self
        } else if OverrideRemoteNotification.includedInNotification(self) {
            notificationType = OverrideRemoteNotification.self
        } else if OverrideCancelRemoteNotification.includedInNotification(self) {
            notificationType = OverrideCancelRemoteNotification.self
        } else {
            throw RemoteNotificationError.unhandledNotification(self)
        }
        return try notificationType.init(dictionary: self)
    }
}
