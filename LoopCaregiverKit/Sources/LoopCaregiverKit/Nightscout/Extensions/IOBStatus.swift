//
//  IOBStatus.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/7/23.
//

import Foundation
import NightscoutKit

extension IOBStatus: Equatable {
    public func formattedIOB() -> String {
        guard let iob else {
            return ""
        }
        
        var maxFractionalDigits = 0
        if iob > 1 {
            maxFractionalDigits = 1
        } else {
            maxFractionalDigits = 2
        }
        
        let iobString = iob.formatted(
            .number
            .precision(.fractionLength(0...maxFractionalDigits))
        )

        return iobString + " U"
    }
    
    public static func == (lhs: IOBStatus, rhs: IOBStatus) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
        lhs.iob == rhs.iob
    }
}
