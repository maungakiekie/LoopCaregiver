//
//  LatestGlucoseRowView.swift
//
//
//  Created by Bill Gestrich on 7/4/24.
//

import Foundation
import LoopCaregiverKit
import SwiftUI

public struct LatestGlucoseRowView: View {
    public let viewModel: WidgetViewModel
    
    public init(glucoseValue: GlucoseTimelineValue) {
        self.viewModel = WidgetViewModel(glucoseValue: glucoseValue)
    }
    
    public var body: some View {
        HStack(spacing: 3) {
            Text(viewModel.currentGlucoseText)
                .strikethrough(viewModel.isGlucoseStale)
                .foregroundStyle(egvColor)
                .font(.headline)
                .bold()
            if let currentTrendImageName = viewModel.currentTrendImageName {
                Image(systemName: currentTrendImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(egvColor)
                    .frame(maxWidth: 13)
                    .accessibilityLabel(Text(currentTrendImageName))
            }
            if let currentGlucoseChangeText = viewModel.currentGlucoseChangeText {
                Text(currentGlucoseChangeText)
                    .strikethrough(viewModel.isGlucoseStale)
                    .foregroundStyle(egvColor)
                    .font(.headline)
                    .bold()
            }
            if !viewModel.currentGlucoseDateText.isEmpty {
                Text("(" + viewModel.currentGlucoseDateText + ")")
                    .strikethrough(viewModel.isGlucoseStale)
                    .font(.footnote)
                    .bold()
            }
        }
    }
    
    var egvColor: Color {
        viewModel.egvValueColor
    }
}
