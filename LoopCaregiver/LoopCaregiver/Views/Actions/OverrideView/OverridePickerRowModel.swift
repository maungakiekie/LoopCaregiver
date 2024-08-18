//
//  OverridePickerRowModel.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/9/24.
//

import Foundation
import NightscoutKit

struct OverridePickerRowModel: Hashable {
    let targetRange: ClosedRange<Double>?
    let insulinNeedsScaleFactor: Double?
    let symbol: String?
    let duration: TimeInterval
    let name: String?
    let isActive: Bool
    let indefiniteDurationAllowed: Bool

    init(preset: TemporaryScheduleOverride, activeOverride: TemporaryScheduleOverride?) {
        let indefiniteDurationAllowed = preset.duration == 0
        if let activeOverride {
            self.targetRange = activeOverride.targetRange
            self.insulinNeedsScaleFactor = activeOverride.insulinNeedsScaleFactor
            self.symbol = activeOverride.symbol
            self.duration = activeOverride.duration
            self.name = activeOverride.name
            self.isActive = true
            self.indefiniteDurationAllowed = indefiniteDurationAllowed
        } else {
            self.targetRange = preset.targetRange
            self.insulinNeedsScaleFactor = preset.insulinNeedsScaleFactor
            self.symbol = preset.symbol
            self.duration = preset.duration
            self.name = preset.name
            self.isActive = false
            self.indefiniteDurationAllowed = indefiniteDurationAllowed
        }
    }

    func presentableDescription() -> String {
        return "\(symbol ?? "") \(name ?? "")"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: OverridePickerRowModel, rhs: OverridePickerRowModel) -> Bool {
        return lhs.name == rhs.name &&
        lhs.symbol == rhs.symbol &&
        lhs.duration == rhs.duration &&
        lhs.targetRange == rhs.targetRange &&
        lhs.insulinNeedsScaleFactor == rhs.insulinNeedsScaleFactor &&
        lhs.isActive == rhs.isActive
    }
}
