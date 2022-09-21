//
//  countdownComponents.swift
//  Hound
//
//  Created by Jonathan Xakellis on 3/4/22.
//  Copyright © 2022 Jonathan Xakellis. All rights reserved.
//

import Foundation

final class CountdownComponents: NSObject, NSCoding, NSCopying {
    
    // MARK: - NSCopying
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = CountdownComponents()
        copy.executionInterval = executionInterval
        copy.intervalElapsed = intervalElapsed
        return copy
    }
    
    // MARK: - NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        // <= build 8000 "executionInterval"
        executionInterval = aDecoder.decodeObject(forKey: KeyConstant.countdownExecutionInterval.rawValue) as? Double ?? aDecoder.decodeObject(forKey: "executionInterval") as? Double ?? executionInterval
        // <= build 8000 "intervalElapsed"
        intervalElapsed = aDecoder.decodeObject(forKey: KeyConstant.countdownIntervalElapsed.rawValue) as? Double ?? aDecoder.decodeObject(forKey: "intervalElapsed") as? Double ?? intervalElapsed
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(executionInterval, forKey: KeyConstant.countdownExecutionInterval.rawValue)
        aCoder.encode(intervalElapsed, forKey: KeyConstant.countdownIntervalElapsed.rawValue)
    }
    
    // MARK: - Main
    
    override init() {
        super.init()
    }
    
    convenience init(executionInterval: TimeInterval?, intervalElapsed: TimeInterval?) {
        self.init()
        
        if let executionInterval = executionInterval {
            self.executionInterval = executionInterval
        }
        if let intervalElapsed = intervalElapsed {
            self.intervalElapsed = intervalElapsed
        }
    }
    
    /// Interval at which a timer should be triggered for reminder
    var executionInterval: TimeInterval = ClassConstant.ReminderComponentConstant.defaultCountdownExecutionInterval
    
    /// How much time of the interval of been used up, this is used for when a timer is paused and then unpaused and have to calculate remaining time
    var intervalElapsed: TimeInterval = TimeInterval(0)
    
}
