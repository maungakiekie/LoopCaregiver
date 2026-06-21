//
//  ContentView.swift
//  LoopCaregiverWatchApp Watch App
//
//  Created by Bill Gestrich on 10/27/23.
//

import Foundation
import LoopCaregiverKit
import SwiftUI
import WidgetKit

struct ContentView: View {
    @EnvironmentObject var accountService: AccountServiceManager
    var deepLinkHandler: DeepLinkHandler
    @EnvironmentObject var settings: CaregiverSettings
    @EnvironmentObject var watchService: WatchService
    @Environment(\.scenePhase)
    var scenePhase
    
    @State private var deepLinkErrorShowing = false
    @State private var deepLinkErrorText: String = ""

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                if let looperService = accountService.selectedLooperService {
                    HomeView(connectivityManager: watchService, accountService: accountService, looperService: looperService)
                } else {
                    Text("Open Caregiver Settings on your iPhone and tap 'Setup Watch'")
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                NavigationLink {
                                    WatchSettingsView(
                                        connectivityManager: watchService,
                                        accountService: accountService,
                                        settings: settings
                                    )
                                } label: {
                                    Label("Settings", systemImage: "gear")
                                }
                            }
                        }
                }
            }
            .alert(deepLinkErrorText, isPresented: $deepLinkErrorShowing) {
                Button(role: .cancel) {
                } label: {
                    Text("OK")
                }
            }
        }
        .onChange(of: watchService.receivedWatchConfiguration, {
            if let receivedWatchConfiguration = watchService.receivedWatchConfiguration {
                Task {
                    await updateWatchConfiguration(watchConfiguration: receivedWatchConfiguration)
                }
            }
        })
        .onOpenURL(perform: { url in
            Task {
                do {
                    try await deepLinkHandler.handleDeepLinkURL(url)
                    // reloadWidget()
                } catch {
                    print("Error handling deep link: \(error)")
                    deepLinkErrorText = error.localizedDescription
                    deepLinkErrorShowing = true
                    WidgetCenter.shared.invalidateConfigurationRecommendations()
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        })
        .onAppear {
            if accountService.selectedLooper == nil {
                do {
                    try watchService.requestWatchConfiguration()
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                reloadWidget()
            } else if newPhase == .background {
                reloadWidget()
            }
        }
    }

    @MainActor
    func updateWatchConfiguration(watchConfiguration: WatchConfiguration) async {
        let existingLoopers = accountService.loopers

        let removedLoopers = existingLoopers.filter { existingLooper in
            return !watchConfiguration.loopers.contains(where: { $0.id == existingLooper.id })
        }
        
        for looper in removedLoopers {
            try? accountService.removeLooper(looper)
        }

        let addedLoopers = watchConfiguration.loopers.filter { configurationLooper in
            return !existingLoopers.contains(where: { $0.id == configurationLooper.id })
        }

        for looper in addedLoopers {
            try? accountService.addLooper(looper)
        }

        // To ensure new Loopers show in widget recommended configurations.
        WidgetCenter.shared.invalidateConfigurationRecommendations()
    }

    func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    let composer = ServiceComposerPreviews()
    return ContentView(deepLinkHandler: composer.deepLinkHandler)
        .environmentObject(composer.accountServiceManager)
        .environmentObject(composer.settings)
        .environmentObject(composer.watchService)
}
