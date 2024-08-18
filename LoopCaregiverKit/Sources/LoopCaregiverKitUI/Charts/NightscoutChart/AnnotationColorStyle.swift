//
//  AnnotationColorStyle.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 4/12/24.
//

import Foundation
import SwiftUI

enum AnnotationColorStyle {
    case brown
    case blue
    case red
    case yellow
    case black
    case clear

    func color(scheme: ColorScheme) -> Color {
        switch self {
        case .brown:
            if scheme == .dark {
                return .white
            } else {
                return Color(.sRGB, red: 0.7, green: 0.6, blue: 0.5)
            }
        case .blue:
            return .blue
        case .red:
            return .red
        case .yellow:
            return .yellow
        case .black:
            return .black
        case .clear:
            return .clear
        }
    }
}
