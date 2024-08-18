//
//  LargeWidgetView.swift
//
//
//  Created by Bill Gestrich on 7/8/24.
//

import Foundation
import LoopCaregiverKit
import SwiftUI

public struct LargeWidgetView: View {
    public let viewModel: WidgetViewModel
    
    public init(glucoseValue: GlucoseTimelineValue) {
        self.viewModel = WidgetViewModel(glucoseValue: glucoseValue)
    }
    
    public var body: some View {
        VStack {
            HStack {
                CurrentGlucoseComboView(glucoseSample: viewModel.latestGlucose, lastGlucoseChange: viewModel.lastGlucoseChange, displayUnits: viewModel.glucoseDisplayUnits)
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        Text("IOB:")
                        Text("COB:")
                    }
                    VStack(alignment: .leading) {
                        Text(viewModel.glucoseValue.treatmentData.currentIOB?.formattedIOB() ?? "")
                        Text(viewModel.glucoseValue.treatmentData.currentCOB?.formattedCOB() ?? "")
                    }
                }
                .font(.footnote)
            }
            if let (override, status) = viewModel.glucoseValue.treatmentData.overrideAndStatus {
                ActiveOverrideInlineView(activeOverride: override, status: status)
            }
            if let recommendedBolus = viewModel.glucoseValue.treatmentData.recommendedBolus {
                TitleSubtitleRowView(
                    title: "Recommended Bolus",
                    subtitle: LocalizationUtils.presentableStringFromBolusAmount(recommendedBolus) + " U"
                )
                .padding([.bottom, .trailing], 5.0)
            }
            NightscoutChartView(
                viewModel: NightscoutChartViewModel(
                    treatmentData: viewModel.treatmentData,
                    timelinePredictionEnabled: true,
                    totalLookbackhours: 6,
                    timelineVisibleLookbackHours: 6,
                    compactMode: false,
                    showChartXAxis: true,
                    showChartYAxis: true
                )
            )
        }
    }
}
