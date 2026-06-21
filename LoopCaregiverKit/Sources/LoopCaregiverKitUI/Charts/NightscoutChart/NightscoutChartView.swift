//
//  NightscoutChartView.swift
//
//
//  Created by Bill Gestrich on 7/6/24.
//

import Charts
import Foundation
import HealthKit
import LoopCaregiverKit
import LoopKit
import NightscoutKit
import SwiftUI

public struct NightscoutChartViewModel: Equatable {
    let treatmentData: CaregiverTreatmentData
    let timelinePredictionEnabled: Bool
    let totalLookbackhours: Int
    var timelineVisibleLookbackHours: Int
    let compactMode: Bool
    let graphTag = 1000
    let showChartXAxis: Bool
    let showChartYAxis: Bool
    
    func allGraphItems() -> [GraphItem] {
        return remoteCommandGraphItems() + carbEntryGraphItems() + bolusGraphItems() + predictionGraphItems() + glucoseGraphItems()
    }
    
    func glucoseGraphItems() -> [GraphItem] {
        return treatmentData.glucoseSamples.map({ $0.graphItem(displayUnit: treatmentData.glucoseDisplayUnits) })
            .filter({ $0.displayTime >= nowDate.addingTimeInterval(-Double(totalLookbackhours) * 60.0 * 60.0 ) })
    }
    
    func predictionGraphItems() -> [GraphItem] {
        return treatmentData.predictedGlucose
            .map({ $0.graphItem(displayUnit: treatmentData.glucoseDisplayUnits) })
            .filter({ $0.displayTime <= nowDate.addingTimeInterval(Double(timelinePredictionHours) * 60.0 * 60.0 ) })
    }
    
    func bolusGraphItems() -> [GraphItem] {
        return treatmentData.bolusEntries
            .map({ $0.graphItem(egvValues: glucoseGraphItems(), displayUnit: treatmentData.glucoseDisplayUnits) })
            .filter({ $0.displayTime >= nowDate.addingTimeInterval(-Double(totalLookbackhours) * 60.0 * 60.0 ) })
    }
    
    func carbEntryGraphItems() -> [GraphItem] {
        return treatmentData.carbEntries
            .map({ $0.graphItem(egvValues: glucoseGraphItems(), displayUnit: treatmentData.glucoseDisplayUnits) })
            .filter({ $0.displayTime >= nowDate.addingTimeInterval(-Double(totalLookbackhours) * 60.0 * 60.0 ) })
    }
    
    func remoteCommandGraphItems() -> [GraphItem] {
        return treatmentData.recentCommands
            .compactMap({ $0.graphItem(egvValues: glucoseGraphItems(), displayUnit: treatmentData.glucoseDisplayUnits) })
            .filter({ $0.displayTime >= nowDate.addingTimeInterval(-Double(totalLookbackhours) * 60.0 * 60.0 ) })
    }
    
    func chartXRange() -> ClosedRange<Date> {
        let maxXDate = nowDate.addingTimeInterval(60 * 60 * TimeInterval(timelinePredictionHours))
        let minXDate = nowDate.addingTimeInterval(-60 * 60 * TimeInterval(totalLookbackhours))
        return minXDate...maxXDate
    }
    
    func chartYRange() -> ClosedRange<Double> {
        return chartYBase()...chartYTop()
    }
    
    func chartYBase() -> Double {
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 0).doubleValue(for: treatmentData.glucoseDisplayUnits)
    }
    
    func chartYTop() -> Double {
        guard let maxGraphYValue = maxValueOfAllGraphItems() else {
            return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 400).doubleValue(for: treatmentData.glucoseDisplayUnits)
        }
        
        if maxGraphYValue >= 300 {
            return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 400).doubleValue(for: treatmentData.glucoseDisplayUnits)
        } else if maxGraphYValue >= 200 {
            return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 300).doubleValue(for: treatmentData.glucoseDisplayUnits)
        } else {
            return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 200).doubleValue(for: treatmentData.glucoseDisplayUnits)
        }
    }
    
    func minValueOfAllGraphItems() -> Double? {
        let minBG = self.glucoseGraphItems().min(by: { $0.value < $1.value })?.quantity.doubleValue(for: .milligramsPerDeciliter)
        var minPredictedY: Double?
        if timelinePredictionEnabled {
            minPredictedY = self.predictionGraphItems().min(by: { $0.value < $1.value })?.quantity.doubleValue(for: .milligramsPerDeciliter)
        }
        
        if let minBG, let minPredictedY {
            return min(minBG, minPredictedY)
        } else if let minBG {
            return minBG
        } else if let minPredictedY {
            return minPredictedY
        } else {
            return nil
        }
    }
    
    func maxValueOfAllGraphItems() -> Double? {
        let maxBGY = self.glucoseGraphItems().max(by: { $0.value < $1.value })?.quantity.doubleValue(for: .milligramsPerDeciliter)
        var maxPredictedY: Double?
        if timelinePredictionEnabled {
            maxPredictedY = self.predictionGraphItems().max(by: { $0.value < $1.value })?.quantity.doubleValue(for: .milligramsPerDeciliter)
        }
        
        if let maxBGY, let maxPredictedY {
            return max(maxBGY, maxPredictedY)
        } else if let maxBGY {
            return maxBGY
        } else if let maxPredictedY {
            return maxPredictedY
        } else {
            return nil
        }
    }
    
    func xAxisLabelFormatStyle(for date: Date) -> Date.FormatStyle {
        switch visibleFrameHours {
        case 0..<2:
            return .dateTime.hour().minute()
        case 2..<4:
            return .dateTime.hour().minute()
        case 4..<6:
            return .dateTime.hour().minute()
        case 6..<12:
            return .dateTime.hour().minute()
        case 12..<24:
            return .dateTime.hour().minute()
        case 24...:
            return .dateTime.hour().minute()
        default:
            return .dateTime.hour().minute()
        }
    }
    
    var visibleFrameHours: Int {
        return timelineVisibleLookbackHours + timelinePredictionHours
    }
    
    var totalAxisMarks: Int {
        return totalGraphHours / visibleFrameHours * maxVisibleXLabels
    }
    
    var maxVisibleXLabels: Int {
        return compactMode ? 3 : 5
    }
    
    var totalGraphHours: Int {
        return totalLookbackhours + timelinePredictionHours
    }
    
    var timelinePredictionHours: Int {
        guard timelinePredictionEnabled else {
            return 0
        }
        
        return min(6, timelineVisibleLookbackHours)
    }
    
    func getTargetDateRangesAndValues() -> [DateRangeAndValue<LowHighTarget>] {
        var lowHighTargets = [LowHighTarget]()
        guard let defaultProfile = treatmentData.currentProfile?.getDefaultProfile() else {
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
    
    func getNormalizedTargetInUserUnits(target: LowHighTarget) -> (Double, Double) {
        let minimumRange = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 20).doubleValue(for: treatmentData.glucoseDisplayUnits)
        let lowTargetValue = target.highTargetValue.quantity.doubleValue(for: treatmentData.glucoseDisplayUnits)
        let highTargetValue = target.lowTargetValue.quantity.doubleValue(for: treatmentData.glucoseDisplayUnits)
        let targetRange = highTargetValue - lowTargetValue
        if targetRange < minimumRange {
            let difference = minimumRange - targetRange
            let adjustedLowTarget = lowTargetValue - (difference / 2.0)
            let adjustedHighTarget = highTargetValue + (difference / 2.0)
            return (adjustedLowTarget, adjustedHighTarget)
        }
        return (lowTargetValue, highTargetValue)
    }
    
    var nowDate: Date {
        // This allows the view to respond to external updates
        // Without this, the view won't update when displayed in
        // a widget.
        return max(treatmentData.creationDate, Date())
    }
    
    struct LowHighTarget: OffsetItem {
        let lowTargetValue: ProfileSet.ScheduleItem
        let highTargetValue: ProfileSet.ScheduleItem
        
        var offset: TimeInterval {
            return lowTargetValue.offset
        }
    }
}

struct NightscoutChartView: View {
    let viewModel: NightscoutChartViewModel
    
    var body: some View {
        Chart {
            ForEach(viewModel.getTargetDateRangesAndValues(), id: \.range) { dateRangeAndValue in
                RectangleMark(
                    xStart: .value("Time", dateRangeAndValue.range.lowerBound),
                    xEnd: .value("Time", dateRangeAndValue.range.upperBound),
                    yStart: .value("Reading", viewModel.getNormalizedTargetInUserUnits(target: dateRangeAndValue.value).0),
                    yEnd: .value("Reading", viewModel.getNormalizedTargetInUserUnits(target: dateRangeAndValue.value).1)
                )
                .opacity(0.2)
                .foregroundStyle(Color("glucose", bundle: .module))
            }
            ForEach(viewModel.glucoseGraphItems()) {
                PointMark(
                    x: .value("Time", $0.displayTime),
                    y: .value("Reading", $0.value)
                )
                .foregroundStyle(by: .value("Reading", $0.colorType))
                .symbol(
                    FilledCircle()
                )
            }
            if viewModel.timelinePredictionEnabled {
                ForEach(viewModel.predictionGraphItems()) {
                    LineMark(
                        x: .value("Time", $0.displayTime),
                        y: .value("Reading", $0.value)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [7.0, 3.0]))
                    .foregroundStyle(Color(uiColor: .magenta.withAlphaComponent(0.5)))
                }
            }
            ForEach(viewModel.bolusGraphItems()) { graphItem in
                PointMark(
                    x: .value("Time", graphItem.displayTime),
                    y: .value("Reading", graphItem.value)
                )
                .foregroundStyle(by: .value("Reading", ColorType.clear))
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    return TreatmentAnnotationView(graphItem: graphItem)
                }
            }
            ForEach(viewModel.carbEntryGraphItems()) { graphItem in
                PointMark(
                    x: .value("Time", graphItem.displayTime),
                    y: .value("Reading", graphItem.value)
                )
                .foregroundStyle(by: .value("Reading", ColorType.clear))
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    return TreatmentAnnotationView(graphItem: graphItem)
                }
            }
            ForEach(viewModel.remoteCommandGraphItems()) { graphItem in
                PointMark(
                    x: .value("Time", graphItem.displayTime),
                    y: .value("Reading", graphItem.value)
                )
                .foregroundStyle(by: .value("Reading", ColorType.clear))
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    return TreatmentAnnotationView(graphItem: graphItem)
                }
            }
            RuleMark(
                x: .value("Now", nowDate)
            )
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            .foregroundStyle(.primary)
        }
        // Make sure the domain values line up with what is in foregroundStyle above.
        .chartForegroundStyleScale(domain: ColorType.membersAsRange(), range: ColorType.allCases.map({ $0.color }), type: .none)
        .chartXScale(domain: viewModel.chartXRange())
        .chartYScale(domain: viewModel.chartYRange())
        .chartYAxis {
            if !viewModel.showChartYAxis {
                AxisMarks(
                    preset: .aligned,
                    position: .trailing,
                    values: .stride(by: (viewModel.chartYRange().upperBound - viewModel.chartYRange().lowerBound) / 2 ),
                    stroke: StrokeStyle(
                        lineWidth: 0,
                        lineCap: .butt,
                        lineJoin: .bevel,
                        miterLimit: 1,
                        dash: [],
                        dashPhase: 1
                    )
                )
            } else {
                AxisMarks(
                    preset: .aligned,
                    position: .trailing,
                    values: .stride(by: (viewModel.chartYRange().upperBound - viewModel.chartYRange().lowerBound) / 4 ),
                    stroke: StrokeStyle(
                        lineWidth: 1,
                        lineCap: .butt,
                        lineJoin: .bevel,
                        miterLimit: 1,
                        dash: [],
                        dashPhase: 1
                    )
                )
            }
        }
        .chartXAxis {
            if viewModel.showChartXAxis {
                AxisMarks(position: .bottom, values: AxisMarkValues.automatic(desiredCount: viewModel.totalAxisMarks, roundLowerBound: false, roundUpperBound: false)) { date in
                    if let date = date.as(Date.self) {
                        AxisValueLabel(format: viewModel.xAxisLabelFormatStyle(for: date), collisionResolution: .truncate)
                    } else {
                        AxisValueLabel(format: viewModel.xAxisLabelFormatStyle(for: nowDate))
                    }
                    AxisGridLine(centered: true)
                }
            }
        }
    }
    
    var nowDate: Date {
        // This allows the view to respond to external updates
        // Without this, the view won't update when displayed in
        // a widget.
        return max(viewModel.treatmentData.creationDate, Date())
    }
    
    var timelineCount: Int {
        let timelineRefreshKey = "time-line-refresh"
        return UserDefaults.standard.value(forKey: timelineRefreshKey) as? Int ?? 0
    }
}
