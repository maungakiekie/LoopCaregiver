//
//  TimelineWatchProvider.swift
//  LoopCaregiverWatchAppExtension
//
//  Created by Bill Gestrich on 12/18/23.
//

import Foundation
import LoopCaregiverKit
import LoopKit
import SwiftUI
import WidgetKit

class TimelineWatchProvider: AppIntentTimelineProvider {
    let providerShared = TimelineProviderShared()
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<GlucoseTimeLineEntry> {
        return await providerShared.timeline(for: configuration.looperID, looperName: configuration.name)
    }
    
    /// Shows the first time widget appears on watchface and when redacted
    func placeholder(in context: Context) -> GlucoseTimeLineEntry {
        return providerShared.placeholder()
    }

    /// Shows when widget is in the gallery and other "transient" times per docs.
    /// This does not seem to be called on the Watch.
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> GlucoseTimeLineEntry {
        return await providerShared.snapshot(for: configuration.looperID, looperName: configuration.name, context: context)
    }
    
    /// Used to recommend Looper configurations on Watch only since WatchOS
    /// does not offer a dedicated interface for configurations.
    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        return providerShared.availableLoopers().compactMap({ looper in
            let appIntent = ConfigurationAppIntent(looperID: looper.id, name: looper.name)
            guard let name = appIntent.name else { return nil }
            return AppIntentRecommendation(intent: appIntent, description: name)
        })
    }
}
