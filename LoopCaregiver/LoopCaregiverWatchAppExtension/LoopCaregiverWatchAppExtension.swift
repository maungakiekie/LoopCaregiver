//
//  LoopCaregiverWatchAppExtension.swift
//  LoopCaregiverWatchAppExtension
//
//  Created by Bill Gestrich on 10/27/23.
//

import HealthKit
import LoopCaregiverKit
import LoopCaregiverKitUI
import LoopKit
import SwiftUI
import WidgetKit

@main
struct LoopCaregiverWatchAppExtension: Widget {
    let kind: String = "LoopCaregiverWatchAppExtension"
    let provider = TimelineWatchProvider()
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: provider) { entry in
            Group {
                switch entry {
                case .success(let glucoseValue):
                    WidgetView(glucoseValue: glucoseValue)
                case .failure(let error):
                    WidgetErrorView(error: error)
                }
            }
            .widgetURL(entry.selectLooperDeepLink().url)
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct WidgetView: View {
    var glucoseValue: GlucoseTimelineValue
    @Environment(\.widgetFamily)
    var family
    
    @ViewBuilder var body: some View {
        switch family {
        case .accessoryInline:
            LatestGlucoseRowView(glucoseValue: glucoseValue)
        case .accessoryCircular:
            LatestGlucoseCircularView(glucoseValue: glucoseValue)
        case .accessoryRectangular:
            LatestGlucoseRectangularView(glucoseValue: glucoseValue)
        default:
            LatestGlucoseCircularView(glucoseValue: glucoseValue)
        }
    }
}

struct WidgetErrorView: View {
    var error: GlucoseTimeLineEntryError
    @Environment(\.widgetFamily)
    var family
    
    @ViewBuilder var body: some View {
        switch family {
        case .accessoryInline:
            Text(error.localizedDescription)
        case .accessoryCircular:
            Text("?")
        case .accessoryRectangular:
            Text(error.localizedDescription)
        default:
            Text(error.localizedDescription)
        }
    }
}

// TODO: These won't build when LoopCaregiverWidget_Previews, in another target/file is enabled.

#Preview(as: .accessoryCorner) {
    LoopCaregiverWatchAppExtension()
} timeline: {
    GlucoseTimeLineEntry.previewsEntry()
}

#Preview(as: .accessoryCircular) {
    LoopCaregiverWatchAppExtension()
} timeline: {
    GlucoseTimeLineEntry.previewsEntry()
}

#Preview(as: .accessoryRectangular) {
    LoopCaregiverWatchAppExtension()
} timeline: {
    GlucoseTimeLineEntry.previewsEntry()
}

#Preview(as: .accessoryInline) {
    LoopCaregiverWatchAppExtension()
} timeline: {
    GlucoseTimeLineEntry.previewsEntry()
}
