//
//  WatchSettingsView.swift
//  LoopCaregiverWatchApp
//
//  Created by Bill Gestrich on 12/26/23.
//

import LoopCaregiverKit
import SwiftUI
import WidgetKit

struct WatchSettingsView: View {
    @ObservedObject var connectivityManager: WatchService
    @ObservedObject var accountService: AccountServiceManager
    @ObservedObject var settings: CaregiverSettings
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var selectedLooper: Looper?
    
    @AppStorage("lastPhoneDebugMessage", store: UserDefaults(suiteName: Bundle.main.appGroupSuiteName))
    var lastPhoneDebugMessage: String = ""
    @State private var glucosePreference: GlucoseUnitPrefererence = .milligramsPerDeciliter
    
    var body: some View {
        VStack {
            Form {
                Picker("Looper", selection: $selectedLooper) {
                    ForEach(accountService.loopers) { looper in
                        Text(looper.name).tag(looper as Looper?)
                    }
                }
                Picker("Glucose", selection: $glucosePreference, content: {
                    ForEach(GlucoseUnitPrefererence.allCases, id: \.self, content: { item in
                        Text(item.presentableDescription).tag(item)
                    })
                })
                Toggle("Show Prediction", isOn: $settings.timelinePredictionEnabled)
                Section("Phone Connectivity") {
                    LabeledContent("Session Supported", value: connectivityManager.sessionsSupported() ? "YES" : "NO")
                    LabeledContent("Session Activated", value: connectivityManager.activated ? "YES" : "NO")
                    LabeledContent("Companion App Inst", value: connectivityManager.isCounterpartAppInstalled() ? "YES" : "NO")
                    LabeledContent("Phone Reachable", value: connectivityManager.isReachable() ? "YES" : "NO")
                    LabeledContent("Network", value: settingsViewModel.networkAvailable ? "YES" : "NO")
                }
                Section("Widgets") {
                    Button(action: {
                        WidgetCenter.shared.invalidateConfigurationRecommendations()
                    }, label: {
                        Text("Invalidate Recommendations")
                    })
                    Button(action: {
                        WidgetCenter.shared.reloadAllTimelines()
                    }, label: {
                        Text("Reload Timeline")
                    })
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            self.glucosePreference = settings.glucosePreference
        }
        .onChange(of: glucosePreference, {
            if settings.glucosePreference != glucosePreference {
                settings.glucosePreference = glucosePreference
                reloadWidget()
            }
        })
        // selectedLooper Bindings
        .onAppear {
            self.selectedLooper = accountService.selectedLooper
        }
        .onChange(of: selectedLooper) { _, newValue in
            if let newValue, accountService.selectedLooper != newValue {
                do {
                    try accountService.updateActiveLoopUser(newValue)
                } catch {
                    print("Error updating looper: \(error)")
                }
            }
        }
        .onChange(of: accountService.selectedLooper) { _, newValue in
            if self.selectedLooper != newValue {
                self.selectedLooper = newValue
            }
        }
    }
    
    func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
