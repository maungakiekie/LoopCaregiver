//
//  CaregiverTreatmentData.swift
//
//
//  Created by Bill Gestrich on 7/6/24.
//

import HealthKit
import LoopKit
import NightscoutKit

public struct CaregiverTreatmentData: Equatable {
    public let creationDate: Date
    public let glucoseDisplayUnits: HKUnit
    public let glucoseSamples: [NewGlucoseSample]
    public let predictedGlucose: [NewGlucoseSample]
    public let bolusEntries: [BolusNightscoutTreatment]
    public let carbEntries: [CarbCorrectionNightscoutTreatment]
    public let recentCommands: [RemoteCommand]
    public let currentProfile: ProfileSet?
    public let overrideAndStatus: (override: NightscoutKit.TemporaryScheduleOverride, status: NightscoutKit.OverrideStatus)?
    public let currentIOB: IOBStatus?
    public let currentCOB: COBStatus?
    public let recommendedBolus: Double?
    
    public init(
        creationDate: Date? = nil,
        glucoseDisplayUnits: HKUnit,
        glucoseSamples: [NewGlucoseSample],
        predictedGlucose: [NewGlucoseSample],
        bolusEntries: [BolusNightscoutTreatment],
        carbEntries: [CarbCorrectionNightscoutTreatment],
        recentCommands: [RemoteCommand],
        currentProfile: ProfileSet? = nil,
        overrideAndStatus: (override: NightscoutKit.TemporaryScheduleOverride, status: OverrideStatus)?,
        currentIOB: IOBStatus?,
        currentCOB: COBStatus?,
        recommendedBolus: Double?
    ) {
        self.creationDate = creationDate ?? Date()
        self.glucoseDisplayUnits = glucoseDisplayUnits
        self.glucoseSamples = glucoseSamples
        self.predictedGlucose = predictedGlucose
        self.bolusEntries = bolusEntries
        self.carbEntries = carbEntries
        self.recentCommands = recentCommands
        self.currentProfile = currentProfile
        self.overrideAndStatus = overrideAndStatus
        self.currentIOB = currentIOB
        self.currentCOB = currentCOB
        self.recommendedBolus = recommendedBolus
    }
    
    public var lastGlucoseChange: Double? {
        let sortedSamples = glucoseSamples.sorted(by: { $0.date < $1.date })
        return sortedSamples.getLastGlucoseChange(displayUnits: glucoseDisplayUnits)
    }
    
    public static func == (lhs: CaregiverTreatmentData, rhs: CaregiverTreatmentData) -> Bool {
        return lhs.creationDate == rhs.creationDate &&
        lhs.glucoseDisplayUnits == rhs.glucoseDisplayUnits &&
        lhs.glucoseSamples == rhs.glucoseSamples &&
        lhs.predictedGlucose == rhs.predictedGlucose &&
        lhs.bolusEntries == rhs.bolusEntries &&
        lhs.carbEntries == rhs.carbEntries &&
        lhs.recentCommands == rhs.recentCommands &&
        lhs.currentProfile == rhs.currentProfile &&
        lhs.overrideAndStatus?.override == rhs.overrideAndStatus?.override &&
        lhs.overrideAndStatus?.status.timestamp == rhs.overrideAndStatus?.status.timestamp &&
        lhs.currentIOB == rhs.currentIOB &&
        lhs.currentCOB == rhs.currentCOB &&
        lhs.recommendedBolus == rhs.recommendedBolus
    }
}
