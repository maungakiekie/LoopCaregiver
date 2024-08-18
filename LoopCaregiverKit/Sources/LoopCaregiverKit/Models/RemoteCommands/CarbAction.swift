//
//  CarbAction.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/25/22.
//

import Foundation

public struct CarbAction: Codable, Equatable {
    public let amountInGrams: Double
    public let absorptionTime: TimeInterval?
    public let foodType: String?
    public let startDate: Date?

    public init(amountInGrams: Double, absorptionTime: TimeInterval? = nil, foodType: String? = nil, startDate: Date? = nil) {
        self.amountInGrams = amountInGrams
        self.absorptionTime = absorptionTime
        self.foodType = foodType
        self.startDate = startDate
    }
}
