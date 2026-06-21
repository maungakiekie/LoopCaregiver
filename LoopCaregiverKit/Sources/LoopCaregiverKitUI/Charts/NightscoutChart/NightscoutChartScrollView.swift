//
//  NightscoutChartScrollView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import Charts
import Combine
import HealthKit
import LoopCaregiverKit
import LoopKit
import SwiftUI

public struct NightscoutChartScrollView: View {
    @ObservedObject var settings: CaregiverSettings
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @State private var scrollRequestSubject = PassthroughSubject<ScrollType, Never>()
    let compactMode: Bool
    public static let timelineLookbackIntervals = [1, 3, 6, 12, 24]
    @AppStorage(UserDefaults.standard.timelineVisibleLookbackHoursKey)
    private var timelineVisibleLookbackHours = NightscoutChartScrollView.defaultTimelineVisibleLookbackHours

    @State private var graphItemsInPopover: [GraphItem]?

    // TODO: Remove Disabled Zoom View Things
    @State private var lastScrollUpdate: Date?
    private let minScale: CGFloat = 0.10
    private let maxScale: CGFloat = 3.0
    @State private var currentScale: CGFloat = 1.0

    @Environment(\.scenePhase)
    private var scenePhase
    
    public init(settings: CaregiverSettings, remoteDataSource: RemoteDataServiceManager, compactMode: Bool) {
        self.settings = settings
        self.remoteDataSource = remoteDataSource
        self.compactMode = compactMode
    }

    public var body: some View {
        GeometryReader { containerGeometry in
            ZoomableScrollView { zoomScrollViewProxy in
                NightscoutChartView(viewModel: graphViewModel)
                    .chartOverlay { chartProxy in
                        GeometryReader { chartGeometry in
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .accessibilityAddTraits(.isButton)
                                .onTapGesture(count: 2) { tapLocation in
                                    switch timelineVisibleLookbackHours {
                                    case 6:
                                        updateTimelineHours(1)
                                    default:
                                        updateTimelineHours(6)
                                    }
                                    scrollRequestSubject.send(.contentPoint(tapLocation))
                                }
                                .onTapGesture(count: 1) { tapLocation in
                                    if let (date, glucose) = chartProxy.value(at: tapLocation, as: (Date, Double).self) {
                                        let items = getNearbyGraphItems(date: date, value: glucose, chartProxy: chartProxy)
                                        guard !items.isEmpty else {
                                            return
                                        }
                                        graphItemsInPopover = items
                                    }
                                }
                                .onReceive(scrollRequestSubject) { scrollType in
                                    let lookbackHours = CGFloat(graphViewModel.totalGraphHours - graphViewModel.timelinePredictionHours)
                                    let lookBackWidthRatio = lookbackHours / CGFloat(graphViewModel.totalGraphHours)
                                    let axisWidth = chartGeometry.size.width - chartProxy.plotAreaSize.width
                                    let graphWithoutYAxisWidth = (containerGeometry.size.width * zoomLevel) - axisWidth
                                    let lookbackWidth = graphWithoutYAxisWidth * lookBackWidthRatio
                                    let focusedContentFrame = CGRect(x: 0, y: 0, width: lookbackWidth, height: containerGeometry.size.height)

                                    let request = ZoomScrollRequest(scrollType: scrollType, updatedFocusedContentFrame: focusedContentFrame, zoomAmount: zoomLevel)
                                    zoomScrollViewProxy.handleZoomScrollRequest(request)
                                }
                                .onChange(of: currentScale, perform: { _ in
//                                    if let lastScrollUpdate, Date().timeIntervalSince(lastScrollUpdate) < 0.1 {
//                                        return
//                                    }
//                                    zoomScrollViewProxy.updateZoomKeepingCenter(newValue)
//                                    let centerPosition = CGPoint(x: chartGeometry.size.width / 2.0, y: 100.0)
//                                    zoomScrollViewProxy.updateZoom(newValue, centerPosition)
//                                    lastScrollUpdate = Date()
//                                    scrollRequestSubject.send(.scrollViewCenter)
                                })
                            // TODO: Remove Disabled Zoom View Things
                            // .modifier(PinchToZoom(minScale: 0.10, maxScale: 3.0, scale: $currentScale))
                        }
                    }
                    // TODO: Prefer leading/trailing of 10.0
                    // but that is causing graph centering
                    // issues
                    .padding(.init(top: 5, leading: 0, bottom: 0, trailing: 0)) // Top to prevent top Y label from clipping
                    .onChange(of: timelineVisibleLookbackHours) { _ in
                        // This is to catch updates to the picker
                        scrollRequestSubject.send(.scrollViewCenter)
                    }
                    .onAppear(perform: {
                        scrollRequestSubject.send(.scrollViewCenter)
                        DispatchQueue.main.async { // On the watch only, it won't scroll in onAppear without introducing a delay
                            zoomScrollViewProxy.scrollTrailing()
                        }
                    })
                    .onChange(of: scenePhase) { newPhase in
                        if newPhase == .active {
                            zoomScrollViewProxy.scrollTrailing()
                        }
                    }
            }
        }
        #if os(iOS)
        .popover(item: $graphItemsInPopover) { graphItemsInPopover in
            graphItemsPopoverView(graphItemsInPopover: graphItemsInPopover)
        }
        #elseif os(watchOS)
        .sheet(item: $graphItemsInPopover) { graphItems in
            graphItemsPopoverView(graphItemsInPopover: graphItems)
        }
        #endif
    }
    
    var treatmentData: CaregiverTreatmentData {
        CaregiverTreatmentData(
            glucoseDisplayUnits: settings.glucosePreference.unit,
            glucoseSamples: remoteDataSource.glucoseSamples,
            predictedGlucose: remoteDataSource.predictedGlucose,
            bolusEntries: remoteDataSource.bolusEntries,
            carbEntries: remoteDataSource.carbEntries,
            recentCommands: remoteDataSource.recentCommands,
            currentProfile: remoteDataSource.currentProfile,
            overrideAndStatus: remoteDataSource.activeOverrideAndStatus(),
            currentIOB: remoteDataSource.currentIOB,
            currentCOB: remoteDataSource.currentCOB,
            recommendedBolus: remoteDataSource.recommendedBolus
        )
    }
    
    var graphViewModel: NightscoutChartViewModel {
        NightscoutChartViewModel(
            treatmentData: treatmentData,
            timelinePredictionEnabled: settings.timelinePredictionEnabled,
            totalLookbackhours: 24,
            timelineVisibleLookbackHours: timelineVisibleLookbackHours,
            compactMode: compactMode,
            showChartXAxis: true,
            showChartYAxis: true
        )
    }

    func graphItemsPopoverView(graphItemsInPopover: [GraphItem]) -> some View {
        NavigationStack {
            List {
                ForEach(graphItemsInPopover) { item in
                    switch item.type {
                    case .bolus, .carb:
                        VStack {
                            HStack {
                                Text(item.displayTime, style: .time)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(item.type.presentableName)
                                    Text(item.formattedValue())
                                }
                            }
                            switch item.graphItemState {
                            case .error(let error):
                                Text(error.localizedDescription)
                                    .foregroundColor(.red)
                            default:
                                EmptyView()
                            }
                        }
                    default:
                        EmptyView()
                    }
                }
            }
            #if os(iOS)
            .toolbar(content: {
                Button {
                    self.graphItemsInPopover = nil
                } label: {
                    Text("Done")
                }
            })
            #endif
        }
        .presentationDetents([.medium])
    }

    func updateTimelineHours(_ hours: Int) {
        timelineVisibleLookbackHours = hours
    }

    func getNearbyGraphItems(date: Date, value: Double, chartProxy: ChartProxy) -> [GraphItem] {
        func distanceCalcuator(graphItem: GraphItem, date: Date, value: Double) -> Double {
            guard let graphItemDatePosition = chartProxy.position(forX: graphItem.displayTime) else {
                assertionFailure("Unexpected")
                return Double.infinity
            }

            guard let graphItemValuePosition = chartProxy.position(forY: graphItem.value) else {
                assertionFailure("Unexpected")
                return Double.infinity
            }

            guard let tappedDatePosition = chartProxy.position(forX: date) else {
                assertionFailure("Unexpected")
                return Double.infinity
            }

            guard let tappedValuePosition = chartProxy.position(forY: value) else {
                assertionFailure("Unexpected")
                return Double.infinity
            }

            return hypot(tappedDatePosition - graphItemDatePosition, tappedValuePosition - graphItemValuePosition)
        }

        let tappableGraphItems = graphViewModel.allGraphItems().filter({ graphItem in
            switch graphItem.type {
            case .bolus, .carb:
                return true
            default:
                return false
            }
        })

        let sortedItems = tappableGraphItems.sorted(by: { item1, item2 in
            item1.displayTime < item2.displayTime
        }).filter({ distanceCalcuator(graphItem: $0, date: date, value: value) < 20 })

        if sortedItems.count <= 10 {
            return sortedItems
        } else {
            return Array(sortedItems[0...9])
        }
    }

    var zoomLevel: Double {
        return CGFloat(graphViewModel.totalGraphHours) / CGFloat(graphViewModel.visibleFrameHours)
    }
    
    static var defaultTimelineVisibleLookbackHours: Int {
#if os(watchOS)
        return 1
#else
        return 6
#endif
    }
}

enum GraphItemType {
    case egv
    case predictedBG
    case bolus(Double)
    case carb(Int)

    var presentableName: String {
        switch self {
        case .egv:
            return "Glucose"
        case .predictedBG:
            return "Predicted Glucose"
        case .bolus:
            return "Bolus"
        case .carb:
            return "Carbs"
        }
    }
}

enum GraphItemState {
    case success
    case pending
    case error(LocalizedError)
}

// Required to use [GraphItem] to control popover visibility
extension [GraphItem]: Identifiable {
    public var id: String {
        var combinedUUID = ""
        for item in self {
            combinedUUID.append(item.id.uuidString)
        }
        return combinedUUID
    }
}

extension ColorType: Plottable {
    public var primitivePlottable: Int {
        return self.rawValue
    }

    public typealias PrimitivePlottable = Int

    public init?(primitivePlottable: Int) {
        self.init(rawValue: primitivePlottable)
    }
}

func interpolateEGVValue(egvs: [GraphItem], atDate date: Date ) -> Double {
    switch egvs.count {
    case 0:
        return 0
    case 1:
        return egvs[0].value
    default:
        let priorEGVs = egvs.filter({ $0.displayTime < date })
        guard let greatestPriorEGV = priorEGVs.last else {
            // All after, use first
            return egvs.first!.value
        }

        let laterEGVs = egvs.filter({ $0.displayTime > date })
        guard let leastFollowingEGV = laterEGVs.first else {
            // All prior, use last
            return egvs.last!.value
        }

        return interpolateYValueInRange(yRange: (y1: greatestPriorEGV.value, y2: leastFollowingEGV.value), referenceXRange: (x1: greatestPriorEGV.displayTime, x2: leastFollowingEGV.displayTime), referenceXValue: date)
    }
}

// Given a known value x in a range (x1, x2), interpolate value y, in range (y1, y2)
func interpolateYValueInRange(yRange: (y1: Double, y2: Double), referenceXRange: (x1: Date, x2: Date), referenceXValue: Date) -> Double {
    let referenceRangeDistance = referenceXRange.x2.timeIntervalSince1970 - referenceXRange.x1.timeIntervalSince1970
    let lowerRangeToValueDifference = referenceXValue.timeIntervalSince1970 - referenceXRange.x1.timeIntervalSince1970
    let scaleFactor = lowerRangeToValueDifference / referenceRangeDistance

    let rangeDifference = abs(yRange.y1 - yRange.y2)
    return yRange.y1 + (rangeDifference * scaleFactor)
}
