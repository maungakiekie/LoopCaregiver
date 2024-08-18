//
//  TimelineWidgetProvider.swift
//  LoopCaregiverWidgetExtension
//
//  Created by Bill Gestrich on 6/2/23.
//

import CoreData
import Intents
import LoopCaregiverKit
import LoopKit
import WidgetKit

struct TimelineWidgetProvider: IntentTimelineProvider {
    let providerShared = TimelineProviderShared()
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<GlucoseTimeLineEntry>) -> Void) {
        Task {
            let timeline = await providerShared.timeline(for: configuration.looper?.identifier, looperName: configuration.looper?.displayString)
            completion(timeline)
        }
    }
    
    /// Shows when widget is first created and when user redacts information
    func placeholder(in context: Context) -> GlucoseTimeLineEntry {
        return providerShared.placeholder()
    }

    /// Shows when widget is in the gallery and other "transient" times per docs.
    /// Lockscreen add Widget view:  The suggestions at the top uses this and passes Context.isPreview == true but then it seems to use the IntentHandler.defaultLooper.
    /// That view seems to hang onto old loopers
    /// Lockscreen tap  "LoopCaregiver" row: It seems to use the IntentHandler.defaultLooper.
    /// Home View Add Widget: The view shows this with Context.isPreview == true
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (GlucoseTimeLineEntry) -> Void) {
        Task {
            let entry = await providerShared.snapshot(for: configuration.looper?.identifier, looperName: configuration.looper?.displayString, context: context)
            completion(entry)
        }
    }
    
    // recommendations are only used for the watch.
    // Widgets instead use the IntentHandler
    // func recommendations() -> [IntentRecommendation<ConfigurationIntent>]
}
