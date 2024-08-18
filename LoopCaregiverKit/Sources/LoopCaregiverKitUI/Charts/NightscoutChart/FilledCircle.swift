//
//  FilledCircle.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 4/12/24.
//

import Charts
import Foundation
import SwiftUI

struct FilledCircle: Shape, ChartSymbolShape {
    var perceptualUnitRect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect.scaledBy(0.55))
        return path
    }
}
