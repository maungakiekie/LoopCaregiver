//
//  NightscoutTreatment.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/7/23.
//

import Foundation
import NightscoutKit

// Empty implementation to avoid SwiftLint warning: file_name
extension NightscoutTreatment {
}

public extension [NightscoutTreatment] {
    func bolusTreatments() -> [BolusNightscoutTreatment] {
        return self.compactMap { treatment in
            return treatment as? BolusNightscoutTreatment
        }
    }

    func basalTreatments() -> [TempBasalNightscoutTreatment] {
        return self.compactMap { treatment in
            return treatment as? TempBasalNightscoutTreatment
        }
    }

    func carbTreatments() -> [CarbCorrectionNightscoutTreatment] {
        return self.compactMap { treatment in
            return treatment as? CarbCorrectionNightscoutTreatment
        }
    }

    func overrideTreatments() -> [OverrideTreatment] {
        return self.compactMap { treatment in
            return treatment as? OverrideTreatment
        }
    }

    func noteTreatments() -> [NoteNightscoutTreatment] {
        return self.compactMap { treatment in
            return treatment as? NoteNightscoutTreatment
        }
    }
}
