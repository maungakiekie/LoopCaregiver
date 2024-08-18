//
//  LoopCaregiverWidgetView.swift
//  LoopCaregiverWidgetExtension
//
//  Created by Bill Gestrich on 6/2/23.
//

import Foundation
import LoopCaregiverKit
import LoopCaregiverKitUI
import NightscoutKit
import SwiftUI

struct LoopCaregiverWidgetView: View {
    @ObservedObject var settings: CaregiverSettings
    var entry: GlucoseTimeLineEntry
    @Environment(\.widgetFamily)
    var family
    
    init(entry: GlucoseTimeLineEntry, settings: CaregiverSettings) {
        self.entry = entry
        self.settings = settings
    }
    
    var body: some View {
        VStack {
            switch entry {
            case .success(let glucoseValue):
                switch family {
                case .accessoryRectangular:
                    LatestGlucoseRectangularView(glucoseValue: glucoseValue)
                case .accessoryCircular:
                    LatestGlucoseCircularView(glucoseValue: glucoseValue)
                case .accessoryInline:
                    LatestGlucoseInlineView(glucoseValue: glucoseValue)
                case .systemLarge:
                    LargeWidgetView(glucoseValue: glucoseValue)
                default:
                    Text(glucoseValue.looper.name)
                    LatestGlucoseSquareView(glucoseValue: glucoseValue)
                }
            case .failure(let error):
                switch family {
                case .accessoryRectangular:
                    Text(error.localizedDescription)
                        .font(.footnote)
                    Text(entry.date.description)
                        .font(.footnote)
                case .accessoryCircular:
                    emptyLatestGlucoseView
                default:
                    Text(error.localizedDescription)
                        .font(.footnote)
                    Text(entry.date.description)
                        .font(.footnote)
                }
            }
        }
        .widgetBackground(backgroundView: backgroundView)
        .widgetURL(entry.selectLooperDeepLink().url)
    }
    
    var emptyLatestGlucoseView: some View {
        VStack {
            Text("---")
            Text("---")
        }
    }
    
    var backgroundView: some View {
        Color.clear
    }
    
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
}

extension View {
    // Remove this when iOS 17 is minimum required
    func widgetBackground(backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}
