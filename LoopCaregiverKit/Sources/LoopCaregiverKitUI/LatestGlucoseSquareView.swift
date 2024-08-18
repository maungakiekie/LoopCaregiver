//
//  LatestGlucoseSquareView.swift
//
//
//  Created by Bill Gestrich on 7/4/24.
//

import Foundation
import LoopCaregiverKit
import SwiftUI

public struct LatestGlucoseSquareView: View {
    public let viewModel: WidgetViewModel
    
    public init(glucoseValue: GlucoseTimelineValue) {
        self.viewModel = WidgetViewModel(glucoseValue: glucoseValue)
    }
    
    public var body: some View {
        LatestGlucoseRowView(glucoseValue: viewModel.glucoseValue)
        NightscoutChartView(
            viewModel: NightscoutChartViewModel(
                treatmentData: viewModel.treatmentData,
                timelinePredictionEnabled: true,
                totalLookbackhours: 1,
                timelineVisibleLookbackHours: 1,
                compactMode: true,
                showChartXAxis: false,
                showChartYAxis: false
            )
        )
        .padding(.init(top: 5, leading: 0, bottom: 5, trailing: 0))
        .clipped()
        if let override = viewModel.glucoseValue.treatmentData.overrideAndStatus?.override {
            Text(override.presentableDescription())
                .font(.footnote)
        }
    }
}
