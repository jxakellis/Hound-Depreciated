//
//  MonthlyComponents.swift
//  Hound
//
//  Created by Jonathan Xakellis on 3/4/22.
//  Copyright © 2022 Jonathan Xakellis. All rights reserved.
//

import Foundation

final class MonthlyComponents: NSObject, NSCoding, NSCopying {
    
    // MARK: - NSCopying
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = MonthlyComponents()
        copy.day = self.day
        copy.hour = self.hour
        copy.minute = self.minute
        copy.isSkippingDate = self.isSkippingDate
        return copy
    }
    
    // MARK: - NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        day = aDecoder.decodeInteger(forKey: "day")
        hour = aDecoder.decodeInteger(forKey: "hour")
        minute = aDecoder.decodeInteger(forKey: "minute")
        isSkippingDate = aDecoder.decodeObject(forKey: "isSkippingDate") as? Date
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(day, forKey: "day")
        aCoder.encode(hour, forKey: "hour")
        aCoder.encode(minute, forKey: "minute")
        aCoder.encode(isSkippingDate, forKey: "isSkippingDate")
    }
    
    // MARK: Main
    
    override init() {
        super.init()
    }
    
    convenience init(day: Int?, hour: Int?, minute: Int?, isSkippingDate: Date?) {
        self.init()
        self.day = day ?? self.day
        self.hour = hour ?? self.hour
        self.minute = minute ?? self.minute
        self.isSkippingDate = isSkippingDate
        
    }
    
    // MARK: - Properties
    
    /// Day of the month that a reminder will fire
    private(set) var day: Int = 1
    /// Throws if not within the range of [1,31]
    func changeDay(forDay: Int) throws {
        guard forDay >= 1 && forDay <= 31 else {
            throw ErrorConstant.MonthlyComponentsError.dayInvalid
        }
        day = forDay
        
    }
    
    /// Hour of the day that the reminder will fire
    private(set) var hour: Int = 7
    
    ///  Throws if not within the range of [0,24]
    func changeHour(forHour: Int) throws {
        guard forHour >= 0 && forHour <= 24 else {
            throw ErrorConstant.MonthlyComponentsError.hourInvalid
        }
        
        hour = forHour
    }
    
    // TO DO NOW rework this feature so it works across time zones. Should produce same result anywhere in the world. to figure this out, store secondsFromGMT (-12 hrs to +14 hrs) whenever minutes or hours is updated, therefore the minutes or hours have a relation to a timezone. then use these secondsFromGMT when calculating any date so it might say a different time of day (e.g. 4:00 PM cali, 6:00PM chic) but it always references the same exact point in time. 
    
    /// Minute of the hour that the reminder will fire
    private(set) var minute: Int = 0
    
    /// Throws if not within the range of [0,60]
    func changeMinute(forMinute: Int) throws {
        guard forMinute >= 0 && forMinute <= 60 else {
            throw ErrorConstant.MonthlyComponentsError.minuteInvalid
        }
        
        minute = forMinute
    }
    
    /// Whether or not the next alarm will be skipped
    var isSkipping: Bool {
        return isSkippingDate != nil
    }
    
    /// The date at which the user changed the isSkipping to true.  If is skipping is true, then a certain log date was appended. If unskipped, then we have to remove that previously added log. Slight caveat: if the skip log was modified (by the user changing its date) we don't remove it.
    var isSkippingDate: Date?
    
    // MARK: - Functions
    
    /// This find the next execution date that takes place after the reminderExecutionBasis. It purposelly not factoring in isSkipping.
    func notSkippingExecutionDate(forReminderExecutionBasis reminderExecutionBasis: Date) -> Date {
        
        // there will only be two future executions dates for a day, so we take the first one is the one.
        return futureExecutionDates(forReminderExecutionBasis: reminderExecutionBasis).first ?? ClassConstant.DateConstant.default1970Date
    }
    
    func previousExecutionDate(forReminderExecutionBasis reminderExecutionBasis: Date) -> Date {
        
        // use non skipping version
        let nextTimeOfDay = notSkippingExecutionDate(forReminderExecutionBasis: reminderExecutionBasis)
        
        var preceedingExecutionDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: nextTimeOfDay) ?? ClassConstant.DateConstant.default1970Date
        preceedingExecutionDate = fallShortCorrection(forDate: preceedingExecutionDate)
        return preceedingExecutionDate
    }
    
    /// Factors in isSkipping to figure out the next time of day
    func nextExecutionDate(forReminderExecutionBasis reminderExecutionBasis: Date) -> Date {
        if isSkipping == true {
            return skippingExecutionDate(forReminderExecutionBasis: reminderExecutionBasis)
        }
        else {
            return notSkippingExecutionDate(forReminderExecutionBasis: reminderExecutionBasis)
        }
    }
    
    // MARK: - Private Helper Functions
    
    //// If we add a month to the date, then it might be incorrect and lose accuracy. For example, our day is 31. We are in April so there is only 30 days. Therefore we get a calculated date of April 30th. After adding a month, the result date is May 30th, but it should be 31st because of our day and that May has 31 days. This corrects that.
    private func fallShortCorrection(forDate date: Date) -> Date {
        
        let dayForCalculatedDate = Calendar.current.component(.day, from: date)
        // when adding a month, the day set fell short of what was needed. We need to correct it
        if day > dayForCalculatedDate {
            // We need to find the maximum possible day to set the date to without having it accidentially roll into the next month.
            var calculatedDay: Int {
                let neededDay = day
                guard let maximumDay = Calendar.current.range(of: .day, in: .month, for: date)?.count else {
                    return neededDay
                }
                if neededDay <= maximumDay {
                    return neededDay
                }
                else {
                    return maximumDay
                }
            }
            
            // We have the correct day to set the date to, now we can change it.
            return Calendar.current.date(bySetting: .day, value: calculatedDay, of: date) ?? ClassConstant.DateConstant.default1970Date
        }
        // when adding a month, the day did not fall short of what was needed
        else {
            return date
        }
        
    }
    
    /// Produces an array of at least two with all of the future dates that the reminder will fire given the day of month, hour, and minute
    private func futureExecutionDates(forReminderExecutionBasis reminderExecutionBasis: Date) -> [Date] {
        
        var calculatedDates: [Date] = []
        
        var calculatedDate = reminderExecutionBasis
        
        // finds number of days in the calculated date's month, used for roll over calculations
        guard let numDaysInMonth = Calendar.current.range(of: .day, in: .month, for: calculatedDate)?.count else {
            return [ClassConstant.DateConstant.default1970Date, ClassConstant.DateConstant.default1970Date]
        }
        
        // the day of month is greater than the number of days in the target month, so we just use the last possible day of month to get as close as possible without rolling over into the next month.
        if day > numDaysInMonth {
            calculatedDate = Calendar.current.date(bySetting: .day, value: numDaysInMonth, of: calculatedDate) ?? ClassConstant.DateConstant.default1970Date
            // sets time of day
            calculatedDate = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: calculatedDate, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward) ?? ClassConstant.DateConstant.default1970Date
        }
        // day of month is less than days available in the current month, so no roll over correction needed and traditional method
        else {
            calculatedDate = Calendar.current.date(bySetting: .day, value: day, of: calculatedDate) ?? ClassConstant.DateConstant.default1970Date
            // sets time of day
            calculatedDate = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: calculatedDate, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward) ?? ClassConstant.DateConstant.default1970Date
        }
        
        // We are looking for future dates, not past. If the calculated date is in the past, we correct to make it in the future.
        if reminderExecutionBasis.distance(to: calculatedDate) < 0 {
            calculatedDate = Calendar.current.date(byAdding: .month, value: 1, to: calculatedDate) ?? ClassConstant.DateConstant.default1970Date
            calculatedDate = fallShortCorrection(forDate: calculatedDate)
            
        }
        calculatedDates.append(calculatedDate)
        
        if calculatedDates.count > 1 {
            calculatedDates.sort()
        }
        // should have at least two dates
        else if calculatedDates.count == 1 {
            var appendedDate = Calendar.current.date(byAdding: .month, value: 1, to: calculatedDates[0]) ?? ClassConstant.DateConstant.default1970Date
            appendedDate = fallShortCorrection(forDate: appendedDate)
            
            calculatedDates.append(appendedDate)
        }
        else {
            AppDelegate.generalLogger.warning("Calculated Dates For futureExecutionDates Empty")
            // calculated dates should never be zero, this means there are somehow zero weekdays selected. Handle this weird case by just appending future dates (one 1 week ahead and the other 2 weeks ahead)
            calculatedDates.append(Calendar.current.date(byAdding: .day, value: 7, to: reminderExecutionBasis) ?? ClassConstant.DateConstant.default1970Date)
            calculatedDates.append(Calendar.current.date(byAdding: .day, value: 14, to: reminderExecutionBasis) ?? ClassConstant.DateConstant.default1970Date)
        }
        
        return calculatedDates
    }
    
    /// If a reminder is skipping, then we must find the next soonest reminderExecutionDate. We have to find the execution date that takes place after the skipped execution date (but before any other execution date).
    private func skippingExecutionDate(forReminderExecutionBasis reminderExecutionBasis: Date) -> Date {
        // there will only be two future executions dates for a day, so we take the second one. The first one is the one used for a not skipping
        return futureExecutionDates(forReminderExecutionBasis: reminderExecutionBasis).last ?? ClassConstant.DateConstant.default1970Date
        
    }
    
}
