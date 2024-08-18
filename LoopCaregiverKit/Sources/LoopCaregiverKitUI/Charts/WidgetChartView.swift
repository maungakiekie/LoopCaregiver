//
//  WidgetChartView.swift
//
//
//  Created by Bill Gestrich on 7/4/24.
//

import Charts
import Foundation
import SwiftUI

struct WidgetChartView: View {
    let viewModel: WidgetViewModel
    
    var body: some View {
        Chart {
            ForEach(glucoseGraphItems(), id: \.displayTime) {
                PointMark(
                    x: .value("Time", $0.displayTime),
                    y: .value("Reading", $0.value)
                )
                .foregroundStyle(by: .value("Reading", $0.colorType))
                .symbol(
                    FilledCircle()
                )
            }
            ForEach(viewModel.getTargetDateRangesAndValues(), id: \.range) { dateRangeAndValue in
                RectangleMark(
                    xStart: .value("Time", dateRangeAndValue.range.lowerBound),
                    xEnd: .value("Time", dateRangeAndValue.range.upperBound),
                    yStart: .value("Reading", viewModel.getNormalizedTargetInUserUnits(target: dateRangeAndValue.value).0),
                    yEnd: .value("Reading", viewModel.getNormalizedTargetInUserUnits(target: dateRangeAndValue.value).1)
                )
                .opacity(0.4)
            }
        }
        .chartYAxis {
            AxisMarks(
                preset: .aligned,
                position: .trailing,
                values: .stride(by: (viewModel.chartYRange().upperBound - viewModel.chartYRange().lowerBound) / 2 ),
                stroke: StrokeStyle(
                    lineWidth: 0,
                    lineCap: .butt,
                    lineJoin: .bevel,
                    miterLimit: 1,
                    dash: [],
                    dashPhase: 1
                )
            )
        }
        .chartForegroundStyleScale(domain: ColorType.membersAsRange(), range: ColorType.allCases.map({ $0.color }), type: .none)
        .chartXAxis(.hidden)
        .chartXScale(domain: viewModel.chartXRange())
        .chartYScale(domain: viewModel.chartYRange())
    }
    
    func glucoseGraphItems() -> [GraphItem] {
        return viewModel.chartGlucoseValues().map({ $0.graphItem(displayUnit: viewModel.glucoseDisplayUnits) })
    }
}

#Preview {
    WidgetChartView(viewModel: WidgetViewModel(glucoseValue: .previewsValue()))
}
