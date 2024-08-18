//
//  OffsetCalculator.swift
//
//
//  Created by Bill Gestrich on 7/6/24.
//

import Foundation

struct OffsetCalculator<T: OffsetItem> {
    let offsetItems: [T]
    
    private func getTargetRatePeriods() -> [OffsetAndDurationAndValue<T>] {
        if offsetItems.isEmpty {
            return []
        } else if offsetItems.count == 1 {
            return [OffsetAndDurationAndValue(
                offset: offsetItems[0].offset,
                duration: 86_400,
                value: offsetItems[0]
            )]
        } else {
            var result = [OffsetAndDurationAndValue<T>]()
            for (index, offsetItem) in offsetItems.enumerated() {
                if index == 0 {
                    continue
                }

                let lastOffsetItem = offsetItems[index - 1]
                result.append(
                    OffsetAndDurationAndValue(
                        offset: lastOffsetItem.offset,
                        duration: offsetItem.offset - lastOffsetItem.offset,
                        value: offsetItem
                    )
                )
            }
            
            if !result.isEmpty {
                let lastOffsetItem = offsetItems.last!
                result.append(
                    OffsetAndDurationAndValue(
                        offset: lastOffsetItem.offset,
                        duration: 86_400 - lastOffsetItem.offset,
                        value: lastOffsetItem
                    )
                )
            }
            
            return result
        }
    }
    
    func getDateRangesAndValues(inputRange inputRangeIncludingAllDays: ClosedRange<Date>) -> [DateRangeAndValue<T>] {
        var result = [DateRangeAndValue<T>]()
        for inputRange in breakDateRangeIntoDayRanges(dateRange: inputRangeIncludingAllDays) {
            let midnightOfDayRange = Calendar.current.startOfDay(for: inputRange.lowerBound)
            for offsetDuarationAndValue in getTargetRatePeriods() {
                let valueStartDate = midnightOfDayRange.addingTimeInterval(offsetDuarationAndValue.offset)
                let valueEndDate = valueStartDate.addingTimeInterval(offsetDuarationAndValue.duration)
                guard valueStartDate < inputRange.upperBound else {
                    // Value starts after this input range, skip it.
                    continue
                }
                guard valueEndDate > inputRange.lowerBound else {
                    // Value ends before input range starts - skip it
                    continue
                }
                
                let startDate = Swift.max(valueStartDate, inputRange.lowerBound)
                let endDate = Swift.min(valueEndDate, inputRange.upperBound)
                result.append(DateRangeAndValue(range: ClosedRange(uncheckedBounds: (startDate, endDate)), value: offsetDuarationAndValue.value))
            }
        }
        
        return result
    }
    
    private func breakDateRangeIntoDayRanges(dateRange: ClosedRange<Date>) -> [Range<Date>] {
        var currentDate = dateRange.lowerBound
        var dayRanges: [Range<Date>] = []
        
        // Get user's current calendar
        let calendar = Calendar.current
        
        // Iterate through each day from start date to end date
        while currentDate <= dateRange.upperBound {
            // Calculate start of the current day (midnight), clamped to lower bound of dateRange
            let startOfDay = max(dateRange.lowerBound, calendar.startOfDay(for: currentDate))
            
            // Calculate end of the current day (23:59:59), clamped to upper bound of dateRange
            let nextDayMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: startOfDay)!)
            let endOfDay = min(dateRange.upperBound, nextDayMidnight)
            
            // Create a range from startOfDay to endOfDay (not including endOfDay)
            let dayRange = startOfDay..<endOfDay
            dayRanges.append(dayRange)
            
            // Move currentDate to the next day
            currentDate = nextDayMidnight
        }
        
        return dayRanges
    }

    struct OffsetAndDurationAndValue<Value> {
        let offset: TimeInterval
        let duration: TimeInterval
        let value: Value
    }

    struct DailyOffsetAndValue<Value: OffsetItem> {
        let startSeconds: TimeInterval
        let durationSeconds: TimeInterval
        let value: Value

        func includesDate(_ date: Date) -> Bool {
            let midnight = Calendar.current.startOfDay(for: date)
            let startDate = midnight.addingTimeInterval(startSeconds)
            let endDate = startDate.addingTimeInterval(durationSeconds)
            return date >= startDate && date <= endDate
        }

        func description() -> String {
            return """
            -----
            Start: \(startSeconds / 60.0 / 60.0)
            End: \(startSeconds + durationSeconds / 60.0 / 60.0)
            Description: \(value)
            -----
            """
        }
    }
}

protocol OffsetItem {
    var offset: TimeInterval { get }
}

struct DateRangeAndValue<Value> {
    let range: ClosedRange<Date>
    let value: Value
}
