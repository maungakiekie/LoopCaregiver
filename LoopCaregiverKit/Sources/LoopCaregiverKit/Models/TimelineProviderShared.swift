//
//  TimelineProviderShared.swift
//
//
//  Created by Bill Gestrich on 6/17/24.
//

import Foundation
import LoopKit
import WidgetKit

public struct TimelineProviderShared {
    var composer: ServiceComposer {
        // Fetched regularly as updates to the UserDefaults will not be detected
        // from other processes. See notes in CaregiverSettings for ideas.
        return ServiceComposerProduction()
    }
    
    public init() {
    }
    
    public func timeline(for looperID: String?, looperName: String?) async -> Timeline<GlucoseTimeLineEntry> {
        do {
            let looper = try await getLooper(looperID: looperID, looperName: looperName)
            return await timeline(for: looper)
        } catch {
            return Timeline.createTimeline(error: error, looper: nil)
        }
    }
    
    public func timeline(for looper: Looper) async -> Timeline<GlucoseTimeLineEntry> {
        let timelineRefreshKey = "time-line-refresh"
        var refreshCount = UserDefaults.standard.value(forKey: timelineRefreshKey) as? Int ?? 0
        refreshCount += 1
        UserDefaults.standard.set(refreshCount, forKey: timelineRefreshKey)
        do {
            let value = try await getTimeLineValue(composer: composer, looper: looper)
            var entries = [GlucoseTimeLineEntry]()
            let nowDate = Date()
            
            var nextRequestDate: Date = nowDate.addingTimeInterval(60 * 5) // Default interval
            let nextExpectedGlucoseDate = value.nextExpectedGlucoseDate()
            if nextExpectedGlucoseDate > nowDate {
                nextRequestDate = nextExpectedGlucoseDate.addingTimeInterval(60 * 1) // Extra minute to allow time for upload.
            }
            
            // Create future entries with the most recent glucose value.
            // These would be used if there no new entries coming in.
            let indexCount = 60
            for index in 0..<indexCount {
                let futureValue = value.valueWithDate(nowDate.addingTimeInterval(60 * TimeInterval(index)))
                entries.append(.success(futureValue))
            }
            
            // The last entry is an error entry as we don't want to show any older glucose info at that point.
            let errorDate = nowDate.addingTimeInterval(60.0 * TimeInterval(indexCount))
            let glucoseError = GlucoseTimeLineEntryError(error: TimelineProviderError.missingGlucose, date: errorDate, looper: looper)
            entries.append(.failure(glucoseError))
            return Timeline(entries: entries, policy: .after(nextRequestDate))
        } catch {
            return Timeline.createTimeline(error: error, looper: looper)
        }
    }
    
    public func placeholder() -> GlucoseTimeLineEntry {
        // Treat the placeholder situation as if we are not ready. This seems like a rare case.
        // We may want the UI side to treat this in a special way i.e. show the widget outline
        // but no data.
        return GlucoseTimeLineEntry(error: TimelineProviderError.notReady, date: Date(), looper: nil)
    }
    
    public func previewsEntry() -> GlucoseTimeLineEntry {
        return GlucoseTimeLineEntry.previewsEntry()
    }

    @MainActor
    private func getTimeLineValue(composer: ServiceComposer, looper: Looper) async throws -> GlucoseTimelineValue {
        let nightscoutDataSource = NightscoutDataSource(looper: looper, settings: composer.settings)
        let remoteServiceManager = RemoteDataServiceManager(remoteDataProvider: nightscoutDataSource)
        await remoteServiceManager.updateData()
        let sortedSamples = remoteServiceManager.glucoseSamples
        guard let latestGlucoseSample = sortedSamples.last else {
            throw TimelineProviderError.missingGlucose
        }
        let treatmentData = CaregiverTreatmentData(
            glucoseDisplayUnits: composer.settings.glucosePreference.unit,
            glucoseSamples: sortedSamples,
            predictedGlucose: remoteServiceManager.predictedGlucose,
            bolusEntries: remoteServiceManager.bolusEntries,
            carbEntries: remoteServiceManager.carbEntries,
            recentCommands: remoteServiceManager.recentCommands,
            currentProfile: remoteServiceManager.currentProfile,
            overrideAndStatus: remoteServiceManager.activeOverrideAndStatus(),
            currentIOB: remoteServiceManager.currentIOB,
            currentCOB: remoteServiceManager.currentCOB,
            recommendedBolus: remoteServiceManager.recommendedBolus
        )
        
        return GlucoseTimelineValue(
            looper: looper,
            glucoseSample: latestGlucoseSample,
            treatmentData: treatmentData,
            date: Date()
        )
    }
    
    public func snapshot(for looperID: String?, looperName: String?, context: TimelineProviderContext) async -> GlucoseTimeLineEntry {
        do {
            let looper = try await getLooper(looperID: looperID, looperName: looperName)
            if context.isPreview {
                let fakeGlucoseSample = NewGlucoseSample.previews()
                let treatmentData = CaregiverTreatmentData(
                    glucoseDisplayUnits: composer.settings.glucosePreference.unit,
                    glucoseSamples: [],
                    predictedGlucose: [],
                    bolusEntries: [],
                    carbEntries: [],
                    recentCommands: [],
                    currentProfile: nil,
                    overrideAndStatus: nil,
                    currentIOB: nil,
                    currentCOB: nil,
                    recommendedBolus: nil
                )
                return GlucoseTimeLineEntry(
                    looper: looper,
                    glucoseSample: fakeGlucoseSample,
                    treatmentData: treatmentData,
                    date: Date()
                )
            } else {
                let value = try await getTimeLineValue(composer: composer, looper: looper)
                return GlucoseTimeLineEntry(value: value)
            }
        } catch {
            return GlucoseTimeLineEntry(error: error, date: Date(), looper: nil)
        }
    }
    
    public func availableLoopers() -> [Looper] {
        do {
            return try composer.accountServiceManager.getLoopers()
        } catch {
            print(error)
            return []
        }
    }
    
    private func getLooper(looperID: String?, looperName: String?) async throws -> Looper {
        guard let looperID else {
            throw TimelineProviderError.looperNotConfigured
        }
        let loopers = try composer.accountServiceManager.getLoopers()
        guard let looper = loopers.first(where: { $0.id == looperID || $0.name == looperName }) else {
            throw TimelineProviderError.looperNotFound(looperID, looperName ?? "", loopers.count)
        }

        return looper
    }
    
    private enum TimelineProviderError: LocalizedError {
        case looperNotFound(_ looperID: String, _ looperName: String, _ availableCount: Int)
        case looperNotConfigured
        case notReady
        case missingGlucose
    
        var errorDescription: String? {
            switch self {
            case let .looperNotFound(looperID, looperName, availableCount):
                return "The looper for this widget was not found: \(looperName), (\(looperID.dropLast(30))), (\(availableCount))." + configurationText()
            case .looperNotConfigured:
                return "No looper is configured for this widget. " + configurationText()
            case .notReady:
                return "The widget is not ready to display. Wait a few minutes and try again."
            case .missingGlucose:
                return "Missing glucose. \(Date().formatted(date: .omitted, time: .shortened))"
            }
        }
        
        func configurationText() -> String {
            return "Edit by pressing the widget for 2 seconds, then choose your Looper again."
        }
    }
}

extension Timeline<GlucoseTimeLineEntry> {
    static func createTimeline(error: Error, looper: Looper?) -> Timeline {
        let nextRequestDate = Date().addingTimeInterval(5 * 60)
        return Timeline(entries: [GlucoseTimeLineEntry(error: error, date: Date(), looper: looper)], policy: .after(nextRequestDate))
    }
}
