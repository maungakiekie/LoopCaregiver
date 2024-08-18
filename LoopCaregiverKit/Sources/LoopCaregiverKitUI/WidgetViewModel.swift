//
//  WidgetViewModel.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/2/24.
//

import Foundation
import HealthKit
import LoopCaregiverKit
import LoopKit
import NightscoutKit
import SwiftUI

public struct WidgetViewModel {
    public let glucoseValue: GlucoseTimelineValue
    public let timelineEntryDate: Date
    public let latestGlucose: NewGlucoseSample
    public let lastGlucoseChange: Double?
    public let glucoseDisplayUnits: HKUnit
    public let currentProfile: ProfileSet?
    public let recentGlucoseValues: [NewGlucoseSample]
    public let treatmentData: CaregiverTreatmentData
    
    public init(glucoseValue: GlucoseTimelineValue) {
        self.glucoseValue = glucoseValue
        self.timelineEntryDate = glucoseValue.date
        self.latestGlucose = glucoseValue.glucoseSample
        self.lastGlucoseChange = glucoseValue.treatmentData.lastGlucoseChange
        self.glucoseDisplayUnits = glucoseValue.treatmentData.glucoseDisplayUnits
        self.recentGlucoseValues = glucoseValue.treatmentData.glucoseSamples
        self.currentProfile = glucoseValue.treatmentData.currentProfile
        self.treatmentData = glucoseValue.treatmentData
    }
    
    public var currentGlucoseDateText: String {
        let elapsedMinutes: Double = timelineEntryDate.timeIntervalSince(latestGlucose.date) / 60.0
        let roundedMinutes = Int(exactly: elapsedMinutes.rounded(.up)) ?? 0
        return "\(roundedMinutes)m"
    }
    
    public var isGlucoseStale: Bool {
        return latestGlucose.date < timelineEntryDate.addingTimeInterval(-60 * 15)
    }
    
    public var currentGlucoseAndChangeText: String {
        var toRet = ""
        toRet += "\(currentGlucoseText)"
        
        if let currentGlucoseChangeText {
            toRet += " \(currentGlucoseChangeText)"
        }
        
        return toRet
    }
    
    public var currentGlucoseText: String {
        return latestGlucose.presentableStringValue(displayUnits: glucoseDisplayUnits, includeShortUnits: false)
    }
    
    public var currentGlucoseNumberText: String {
        var toRet = ""
        let latestGlucoseValue = latestGlucose.presentableStringValue(displayUnits: glucoseDisplayUnits, includeShortUnits: false)
        toRet += "\(latestGlucoseValue)"
        
        return toRet
    }
    
    public var currentGlucoseChangeText: String? {
        guard let lastGlucoseChange else {return nil}
        
        guard lastGlucoseChange != 0 else {return nil}
        
        return lastGlucoseChange.formatted(
            .number
                .sign(strategy: .always(includingZero: false))
                .precision(.fractionLength(0...1))
        )
    }
    
    public var currentTrendImageName: String? {
        guard let trend = latestGlucose.trend else {
            return nil
        }
        
        switch trend {
        case .up:
            return "arrow.up.forward"
        case .upUp:
            return "arrow.up"
        case .upUpUp:
            return "arrow.up"
        case .flat:
            return "arrow.right"
        case .down:
            return "arrow.down.forward"
        case .downDown:
            return "arrow.down"
        case .downDownDown:
            return "arrow.down"
        }
    }
    
    public var egvValueColor: Color {
        return ColorType(quantity: latestGlucose.quantity).color
    }
    
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
    
    func chartXRange() -> ClosedRange<Date> {
        let maxXDate = Date()
        let minXDate = Date().addingTimeInterval(-60 * 60 * 2)
        return minXDate...maxXDate
    }
    
    func chartYRange() -> ClosedRange<Double> {
        guard var maxValue = maxGlucose()?.quantity.doubleValue(for: glucoseDisplayUnits) else {
            return 0...300
        }
        
        if let maxTargetValue = maxGlucoseTargetValue(), maxTargetValue > maxValue {
            maxValue = maxTargetValue
        }
        
        let roundValue: (_ val: Double) -> Double = { val in
            if val <= 100 {
                return 100
            }
            let remainder = Int(val) % 100
            if remainder == 0 {
                return val
            }
            let toAdd = 100 - remainder
            return val + Double(toAdd)
        }
        return 0...roundValue(maxValue)
    }
    
    func chartGlucoseValues() -> [NewGlucoseSample] {
        recentGlucoseValues.filter({ $0.date > chartXRange().lowerBound })
    }
    
    func maxGlucose() -> NewGlucoseSample? {
        return chartGlucoseValues().max(by: { $0.quantity < $1.quantity })
    }
    
    func maxGlucoseTargetValue() -> Double? {
        let allTargetValues = getTargetDateRangesAndValues().compactMap { $0.value.highTargetValue.quantity.doubleValue(for: glucoseDisplayUnits) }
        return allTargetValues.max()
    }
    
    struct LowHighTarget: OffsetItem {
        let lowTargetValue: ProfileSet.ScheduleItem
        let highTargetValue: ProfileSet.ScheduleItem
        
        var offset: TimeInterval {
            return lowTargetValue.offset
        }
    }
    
    func getNormalizedTargetInUserUnits(target: LowHighTarget) -> (Double, Double) {
        let minimumRange = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 20).doubleValue(for: glucoseDisplayUnits)
        let lowTargetValue = target.highTargetValue.quantity.doubleValue(for: glucoseDisplayUnits)
        let highTargetValue = target.lowTargetValue.quantity.doubleValue(for: glucoseDisplayUnits)
        let targetRange = highTargetValue - lowTargetValue
        if targetRange < minimumRange {
            let difference = minimumRange - targetRange
            let adjustedLowTarget = lowTargetValue - (difference / 2.0)
            let adjustedHighTarget = highTargetValue + (difference / 2.0)
            return (adjustedLowTarget, adjustedHighTarget)
        }
        return (lowTargetValue, highTargetValue)
    }
    
    func getTargetDateRangesAndValues() -> [DateRangeAndValue<LowHighTarget>] {
        var lowHighTargets = [LowHighTarget]()
        guard let defaultProfile = currentProfile?.getDefaultProfile() else {
            return []
        }
        for index in 0..<defaultProfile.targetLow.count {
            let lowScheduleItem = defaultProfile.targetLow[index]
            let highScheduleItem = defaultProfile.targetHigh[index]
            lowHighTargets.append(LowHighTarget(lowTargetValue: lowScheduleItem, highTargetValue: highScheduleItem))
        }
        
        let calculator = OffsetCalculator(offsetItems: lowHighTargets)
        return calculator.getDateRangesAndValues(inputRange: chartXRange())
    }
}

extension ProfileSet.ScheduleItem {
    var quantity: HKQuantity {
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: value)
    }
}
