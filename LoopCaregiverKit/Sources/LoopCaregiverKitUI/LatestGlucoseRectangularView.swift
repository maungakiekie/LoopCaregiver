//
//  LatestGlucoseRectangularView.swift
//  LoopCaregiverWidgetExtension
//
//  Created by Auggie Fisher on 1/24/24.
//

import HealthKit
import LoopCaregiverKit
import LoopKit
import SwiftUI

public struct LatestGlucoseRectangularView: View {
    public let viewModel: WidgetViewModel
    
    public init(glucoseValue: GlucoseTimelineValue) {
        self.viewModel = WidgetViewModel(glucoseValue: glucoseValue)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
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
        }
    }
}

struct LatestGlucoseRectangularView_Previews: PreviewProvider {
    static var previews: some View {
        LatestGlucoseRectangularView(glucoseValue: .previewsValue())
    }
}
