//
//  ChartsListView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/26/22.
//

import LoopCaregiverKit
import LoopCaregiverKitUI
import LoopKitUI
import SwiftCharts
import SwiftUI

struct ChartsListView: View {
    let looperService: LooperService
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @ObservedObject var settings: CaregiverSettings
    
    @State private var isInteractingWithPredictedChart = false
    @State private var isInteractingWithActiveInsulinChart = false
    @State private var isInteractingWithInsulinDeliveryChart = false
    @State private var isInteractingWithActiveCarbsChart = false
    
    let chartHeight = 200.0
    
    var body: some View {
        VStack(spacing: 5.0) {
            ChartWrapperView(title: "Glucose", subtitle: eventualGlucose(), hideLabels: $isInteractingWithPredictedChart) {
                if !remoteDataSource.glucoseSamples.isEmpty {
                    PredictedGlucoseChartView(
                        remoteDataSource: remoteDataSource,
                        settings: settings,
                        targetGlucoseSchedule: nil,
                        preMealOverride: nil,
                        scheduleOverride: nil,
                        dateInterval: loopGraphInterval,
                        isInteractingWithChart: $isInteractingWithPredictedChart
                    )
                } else {
                    Spacer()
                }
            }
            ChartWrapperView(
                title: "Active Insulin",
                subtitle: remoteDataSource.currentIOB?.formattedIOB() ?? "",
                hideLabels: $isInteractingWithActiveInsulinChart
            ) {
            }
            ChartWrapperView(title: "Insulin Delivery", subtitle: formattedInsulinDelivery(), hideLabels: $isInteractingWithInsulinDeliveryChart) {
                DoseChartView(
                    remoteDataSource: remoteDataSource,
                    settings: settings,
                    targetGlucoseSchedule: nil,
                    preMealOverride: nil,
                    scheduleOverride: nil,
                    dateInterval: loopGraphInterval,
                    isInteractingWithChart: $isInteractingWithInsulinDeliveryChart
                )
            }
            .frame(maxHeight: 150.0)
            ChartWrapperView(title: "Active Carbohydrates", subtitle: remoteDataSource.currentCOB?.formattedCOB() ?? "", hideLabels: $isInteractingWithActiveCarbsChart) {
                /*
                 if remoteDataSource.glucoseSamples.count > 0, remoteDataSource.predictedGlucose.count > 0 {
                 COBChartView(remoteDataSource: remoteDataSource,
                 settings: settings,
                 targetGlucoseSchedule: nil,
                 preMealOverride: nil,
                 scheduleOverride: nil,
                 dateInterval: loopGraphInterval,
                 isInteractingWithChart: $isInteractingWithActiveCarbsChart)
                 } else {
                 Spacer()
                 }
                 */
            }
            TimelineWrapperView(title: "Timeline", settings: settings) {
                HStack {
                    // Using .padding causes the chart overlay GeometryReader to
                    // have an offset that is the padding amount.
                    // Using a custom "padding" solution here with an HStack to avoid this.
                    Spacer(minLength: outerPadding)
                    NightscoutChartScrollView(
                        settings: settings,
                        remoteDataSource: remoteDataSource,
                        compactMode: false
                    )
                    Spacer(minLength: outerPadding)
                }
            }
        }
    }
    
    var outerPadding: Double {
        return 10.0
    }
    
    var loopGraphInterval: DateInterval {
        let hoursLookback = 1.0
        let hoursLookahead = 5.0
        return DateInterval(
            start: Date().addingTimeInterval(60.0 * 60.0 * -hoursLookback),
            duration: 60.0 * 60.0 * hoursLookahead
        )
    }
    
    func eventualGlucose() -> String {
        guard let eventualGlucose = remoteDataSource.predictedGlucose.last else {
            return ""
        }
        
        return "Eventually \(eventualGlucose.presentableStringValue(displayUnits: settings.glucosePreference.unit, includeShortUnits: true))"
    }
    
    func formattedInsulinDelivery() -> String {
        return "" // TODO: Implement this
    }
}

struct ChartWrapperView<ChartContent: View>: View {
    let title: String
    let subtitle: String
    @Binding var hideLabels: Bool
    let chartContent: ChartContent
    let outerPadding = 10.0
    
    init(
        title: String,
        subtitle: String,
        hideLabels: Binding<Bool>,
        @ViewBuilder chartContent: () -> ChartContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self._hideLabels = hideLabels
        self.chartContent = chartContent()
    }
    
    var body: some View {
        VStack {
            TitleSubtitleRowView(title: title, subtitle: subtitle)
                .opacity(hideLabels ? 0.0 : 1.0)
                .padding([.leading, .trailing], outerPadding)
            chartContent
        }
    }
}

struct TimelineWrapperView<ChartContent: View>: View {
    let title: String
    @ObservedObject var settings: CaregiverSettings
    @AppStorage(UserDefaults.standard.timelineVisibleLookbackHoursKey)
    private var timelineVisibleLookbackHours = 6
    let lookbackIntervals = NightscoutChartScrollView.timelineLookbackIntervals
    let chartContent: ChartContent
    
    init(
        title: String,
        settings: CaregiverSettings,
        @ViewBuilder chartContent: () -> ChartContent
    ) {
        self.title = title
        self.settings = settings
        self.chartContent = chartContent()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .bold()
                    .font(.subheadline)
                    .padding([.leading], 10.0)
                Spacer()
                Picker("Range", selection: $timelineVisibleLookbackHours) {
                    ForEach(lookbackIntervals, id: \.self) { period in
                        Text("\(period)h").tag(period)
                    }
                }
            }
            chartContent
        }
    }
}

extension ChartSettings {
    static var `default`: ChartSettings {
        var settings = ChartSettings()
        settings.top = 12
        settings.bottom = 0
        settings.trailing = 8
        settings.axisTitleLabelsToLabelsSpacing = 0
        settings.labelsToAxisSpacingX = 6
        settings.clipInnerFrame = false
        return settings
    }
}

extension ChartColorPalette {
    static var primary: ChartColorPalette {
        return ChartColorPalette(
            axisLine: .axisLineColor,
            axisLabel: .axisLabelColor,
            grid: .gridColor,
            glucoseTint: .glucoseTintColor,
            insulinTint: .insulinTintColor,
            carbTint: .carbTintColor
        )
    }
}
