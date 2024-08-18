//
//  LoopCaregiverWidget.swift
//  LoopCaregiverWidgetExtension
//
//  Created by Bill Gestrich on 6/1/23.
//

import Intents
import LoopCaregiverKit
import LoopKit
import SwiftUI
import WidgetKit

struct LoopCaregiverWidget: Widget {
    let kind: String = "LoopCaregiverWidget"
    let timelineProvider = TimelineWidgetProvider()
    let composer = ServiceComposerProduction()

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: timelineProvider
        ) { entry in
            LoopCaregiverWidgetView(entry: entry, settings: composer.settings)
        }
        .configurationDisplayName("Loop Caregiver")
        .description("Displays Looper's last BG.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular,
            .systemLarge,
            .systemMedium,
            .systemSmall
        ])
    }
}

// Select the LoopCaregiver target for previews
struct LoopCaregiverWidget_Previews: PreviewProvider {
    static var previews: some View {
        let composer = ServiceComposerPreviews()
        return LoopCaregiverWidgetView(entry: .previewsEntry(), settings: composer.settings)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
