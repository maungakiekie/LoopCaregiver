//
//  LatestGlucoseCircularView.swift
//  LoopCaregiverWidgetExtension
//
//  Created by Bill Gestrich on 6/3/23.
//

import HealthKit
import LoopCaregiverKit
import LoopKit
import SwiftUI

public struct LatestGlucoseCircularView: View {
    public let viewModel: WidgetViewModel
    @Environment(\.colorScheme)
    var colorScheme

    public init(glucoseValue: GlucoseTimelineValue) {
        self.viewModel = WidgetViewModel(glucoseValue: glucoseValue)
    }

    public var body: some View {
        VStack {
            Text(viewModel.currentGlucoseDateText)
                .strikethrough(viewModel.isGlucoseStale)
                .font(.footnote)
                .minimumScaleFactor(0.8)
            Text(viewModel.currentGlucoseAndChangeText)
                .foregroundStyle(egvColor)
                .strikethrough(viewModel.isGlucoseStale)
                .bold()
                .minimumScaleFactor(0.8)
            if let currentTrendImageName = viewModel.currentTrendImageName {
                Image(systemName: currentTrendImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(egvColor)
                    .frame(maxWidth: 15)
                    .offset(.init(width: 0.0, height: -7.0))
                    .accessibilityLabel(Text(currentTrendImageName))
                    .minimumScaleFactor(0.8)
            }
        }
    }

    var egvColor: Color {
        colorScheme == .dark ? viewModel.egvValueColor : .primary
    }
}

// TODO: fails to render and breaks other previews after failure

/*
struct CurrentBGView_Previews: PreviewProvider {
    static var previews: some View {
        LatestGlucoseCircularView(glucoseValue: .previewsValue())
    }
}
*/
