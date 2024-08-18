//
//  GraphItem.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 4/12/24.
//

import Foundation
import HealthKit

struct GraphItem: Identifiable, Equatable {
    var id = UUID()
    var type: GraphItemType
    var displayTime: Date
    var displayUnit: HKUnit
    var quantity: HKQuantity
    let graphItemState: GraphItemState

    var value: Double {
        return quantity.doubleValue(for: displayUnit)
    }

    var colorType: ColorType {
        return ColorType(quantity: quantity)
    }

    init(type: GraphItemType, displayTime: Date, quantity: HKQuantity, displayUnit: HKUnit, graphItemState: GraphItemState) {
        self.type = type
        self.displayTime = displayTime
        self.displayUnit = displayUnit
        self.quantity = quantity
        self.graphItemState = graphItemState
    }

    func annotationWidth() -> CGFloat {
        var width: CGFloat = 0.0
        switch self.type {
        case .bolus(let amount):
            width = CGFloat(amount) * 5.0
        case .carb(let amount):
            width = CGFloat(amount) * 0.5
        default:
            width = 0.5
        }

        let minWidth = 8.0
        let maxWidth = 50.0

        if width < minWidth {
            return minWidth
        } else if width > maxWidth {
            return maxWidth
        } else {
            return width
        }
    }

    func annotationHeight() -> CGFloat {
        return annotationWidth() // same
    }

    func fontSize() -> Double {
        var size = 0.0
        switch self.type {
        case .bolus(let amount):
            size = 3 * amount
        case .carb(let amount):
            size = Double(amount) / 2
        default:
            size = 10
        }

        let minSize = 8.0
        let maxSize = 12.0

        if size < minSize {
            return minSize
        } else if size > maxSize {
            return maxSize
        } else {
            return size
        }
    }

    func annotationFillStyle() -> HalfFilledAnnotationView.FillStyle {
        switch self.type {
        case .bolus:
            return .bottomFill
        case .carb:
            return .topFill
        default:
            return .fullFill
        }
    }

    func annotationFillColor() -> AnnotationColorStyle {
        switch self.type {
        case .bolus:
            return .blue
        case .carb:
            return .brown
        default:
            return .black
        }
    }

    func formattedValue() -> String {
        switch self.type {
        case .bolus(let amount):

            var maxFractionalDigits = 0
            if amount > 1 {
                maxFractionalDigits = 1
            } else {
                maxFractionalDigits = 2
            }

            let bolusQuantityString = amount.formatted(
                .number
                .precision(.fractionLength(0...maxFractionalDigits))
            )

            return bolusQuantityString + "u"
        case .carb(let amount):
            return "\(amount)g"
        case .egv:
            return "\(self.value)"
        case .predictedBG:
            return "\(self.value)"
        }
    }

    func annotationLabelPosition() -> GraphItemLabelPosition {
        switch self.type {
        case .bolus:
            return .bottom
        case .carb:
            return .top
        default:
            return .top
        }
    }

    func shouldShowLabel() -> Bool {
        switch self.type {
        case .bolus:
            return true
        default:
            return true
        }
    }

    enum GraphItemLabelPosition {
        case top
        case bottom
    }

    // Equatable

    static func == (lhs: GraphItem, rhs: GraphItem) -> Bool {
        return lhs.id == rhs.id
    }
}
