//
//  LooperService.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/24/22.
//

import Foundation

public class LooperService: ObservableObject, Hashable {
    public let looper: Looper
    public var remoteDataSource: RemoteDataServiceManager

    public init(looper: Looper, remoteDataSource: RemoteDataServiceManager) {
        self.looper = looper
        self.remoteDataSource = remoteDataSource
    }

    // Hashable

    public static func == (lhs: LooperService, rhs: LooperService) -> Bool {
        lhs.looper.id == rhs.looper.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(looper.id)
    }
}
