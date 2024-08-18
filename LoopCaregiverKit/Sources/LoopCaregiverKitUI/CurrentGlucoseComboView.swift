//
//  CurrentGlucoseComboView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 7/8/24.
//

import Foundation
import HealthKit
import LoopKit
import SwiftUI

public struct CurrentGlucoseComboView: View {
    let glucoseSample: NewGlucoseSample?
    let lastGlucoseChange: Double?
    let displayUnits: HKUnit
    
    public init(glucoseSample: NewGlucoseSample? = nil, lastGlucoseChange: Double? = nil, displayUnits: HKUnit) {
        self.glucoseSample = glucoseSample
        self.lastGlucoseChange = lastGlucoseChange
        self.displayUnits = displayUnits
    }
    
    public var body: some View {
        HStack {
            Text(
                glucoseSample?.presentableStringValue(
                    displayUnits: displayUnits,
                    includeShortUnits: false
                ) ?? " "
            )
            .strikethrough(egvIsOutdated())
            .font(.largeTitle)
            .foregroundColor(egvValueColor())
            if let egv = glucoseSample {
                Image(systemName: egv.arrowImageName())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15.0)
                    .foregroundColor(egvValueColor())
                    .accessibilityLabel(egv.arrowImageName())
            }
            VStack {
                Text(lastEGVTimeFormatted())
                    .font(.footnote)
                    .if(egvIsOutdated(), transform: { view in
                        view.foregroundColor(.red)
                    })
                Text(lastEGVDeltaFormatted())
                    .font(.footnote)
            }
        }
    }
    
    func egvIsOutdated() -> Bool {
        guard let currentEGV = glucoseSample else {
            return true
        }
        return Date().timeIntervalSince(currentEGV.date) > 60 * 10
    }

    func lastEGVTimeFormatted() -> String {
        guard let currentEGV = glucoseSample else {
            return ""
        }
        
        return currentEGV.date.formatted(.dateTime.hour().minute())
    }
    
    func lastEGVDeltaFormatted() -> String {
        guard let lastGlucoseChange else {
            return ""
        }
        
        return lastGlucoseChange.formatted(
            .number
                .sign(strategy: .always(includingZero: false))
                .precision(.fractionLength(0...1))
        )
    }
    
    func egvValueColor() -> Color {
        guard let glucoseSample else {
            return .white
        }
        return ColorType(quantity: glucoseSample.quantity).color
    }
}

#Preview {
    CurrentGlucoseComboView(glucoseSample: .previews(), lastGlucoseChange: 10, displayUnits: .internationalUnitsPerHour)
}
