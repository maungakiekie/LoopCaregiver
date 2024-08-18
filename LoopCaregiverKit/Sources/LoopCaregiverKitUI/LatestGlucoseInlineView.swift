//
//  LatestGlucoseInlineView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/2/24.
//

import HealthKit
import LoopCaregiverKit
import LoopKit
import SwiftUI

public struct LatestGlucoseInlineView: View {
    public let viewModel: WidgetViewModel

    public init(glucoseValue: GlucoseTimelineValue) {
        self.viewModel = WidgetViewModel(glucoseValue: glucoseValue)
    }

    public var body: some View {
        HStack {
            Text(statusText)
                .strikethrough(viewModel.isGlucoseStale)
                .font(.headline)
                .bold()
            if let currentTrendImageName = viewModel.currentTrendImageName {
                Image(systemName: currentTrendImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 15)
                    .offset(.init(width: 0.0, height: -7.0))
                    .accessibilityLabel(Text(currentTrendImageName))
            }
        }
    }

    var statusText: String {
        var result = [String]()
        result.append(viewModel.currentGlucoseText)
        if !viewModel.currentGlucoseDateText.isEmpty {
            result.append("(\(viewModel.currentGlucoseDateText))")
        }
        return result.joined(separator: " ")
    }
}

struct LatestGlucoseInlineView_Previews: PreviewProvider {
    static var previews: some View {
        LatestGlucoseInlineView(glucoseValue: .previewsValue())
    }
}
