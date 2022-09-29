//
//  Timing.swift
//  Hound
//
//  Created by Jonathan Xakellis on 11/20/20.
//  Copyright © 2020 Jonathan Xakellis. All rights reserved.
//

import UIKit

protocol TimingManagerDelegate: AnyObject {
    func didUpdateDogManager(sender: Sender, forDogManager: DogManager)
}

final class TimingManager {
    
    // MARK: - Properties
    
    static var delegate: TimingManagerDelegate! = nil
    
    /// If a timeOfDay alarm is being skipped, this array stores all the timers that are responsible for unskipping the alarm when it goes from 1 Day -> 23 Hours 59 Minutes
    private static var isSkippingDisablingTimers: [Timer] = []
    
    // MARK: - Main
    
    /// Initalizes all timers according to the dogManager passed, assumes no timers currently active and if transitioning from Paused to Unpaused (didUnpuase = true) handles logic differently
    static func willInitalize(forDogManager dogManager: DogManager) {
        
        /// Takes a DogManager and potentially a Bool of if all timers were unpaused, goes through the dog manager and finds all enabled reminders under all enabled dogs and sets a timer to fire.
        
        // goes through all dogs
        for dog in dogManager.dogs {
            // makes sure current dog is enabled, as if it isn't then all of its timers arent either
            
            // goes through all reminders in a dog, makes sure a reminder is enabled and its presentation is not being handled
            for reminder in dog.dogReminders.reminders where reminder.reminderIsEnabled == true && reminder.hasAlarmPresentationHandled == false {
                
                guard let reminderExecutionDate = reminder.reminderExecutionDate else {
                    continue
                }
                
                // Sets a timer that executes when the timer should go from isSkipping true -> false, e.g. 1 Day left on a timer that is skipping and when it hits 23 hours and 59 minutes it turns into a regular nonskipping timer.
                if let unskipDate = reminder.unskipDate() {
                    let isSkippingDisabler = Timer(fireAt: unskipDate,
                                                   interval: -1,
                                                   target: self,
                                                   selector: #selector(willUpdateIsSkipping(sender:)),
                                                   userInfo: [KeyConstant.dogId.rawValue: dog.dogId, KeyConstant.reminderId.rawValue: reminder.reminderId],
                                                   repeats: false)
                    
                    isSkippingDisablingTimers.append(isSkippingDisabler)
                    
                    RunLoop.main.add(isSkippingDisabler, forMode: .common)
                }
                
                let timer = Timer(fireAt: reminderExecutionDate,
                                  interval: -1,
                                  target: self,
                                  selector: #selector(self.didExecuteTimer(sender:)),
                                  userInfo: [
                                    KeyConstant.dogManager.rawValue: dogManager,
                                    KeyConstant.dogId.rawValue: dog.dogId,
                                    KeyConstant.reminderId.rawValue: reminder.reminderId
                                  ],
                                  repeats: false)
                RunLoop.main.add(timer, forMode: .common)
                
                reminder.timer?.invalidate()
                reminder.timer = timer
            }
        }
    }
    
    /// invalidateAll timers for the oldDogManager
    static func willReinitalize(forOldDogManager oldDogManager: DogManager, forNewDogManager newDogManager: DogManager) {
        self.invalidateAll(forDogManager: oldDogManager)
        self.willInitalize(forDogManager: newDogManager)
    }
    
    /// Invalidates all timers so it's fresh when time to reinitalize
    static func invalidateAll(forDogManager dogManager: DogManager) {
        for dog in dogManager.dogs {
            for reminder in dog.dogReminders.reminders {
                reminder.timer?.invalidate()
                reminder.timer = nil
            }
        }
        
        for timer in isSkippingDisablingTimers {
            timer.invalidate()
        }
        
        isSkippingDisablingTimers.removeAll()
    }
    
    // MARK: - Timer Actions
    
    /// Used as a selector when constructing timer in willInitalize, when called at an unknown point in time by the timer it triggers helper functions to create both in app notifications and iOS notifications
    @objc private static func didExecuteTimer(sender: Timer) {
        
        // Parses the sender info needed to figure out which reminder's timer fired
        guard let parsedDictionary = sender.userInfo as? [String: Any] else {
            return
        }
        
        let dogManager = parsedDictionary[KeyConstant.dogManager.rawValue] as? DogManager
        let dogId = parsedDictionary[KeyConstant.dogId.rawValue] as? Int
        let reminderId = parsedDictionary[KeyConstant.reminderId.rawValue] as? Int
        
        guard let dogManager = dogManager, let dogId = dogId, let reminderId = reminderId else {
            return
        }
        
        AlarmManager.willShowAlarm(forDogManager: dogManager, forDogId: dogId, forReminderId: reminderId)
    }
    
    /// If a reminder is skipping the next time of day alarm, at some point it will go from 1+ day away to 23 hours and 59 minutes. When that happens then the timer should be changed from isSkipping to normal mode because it just skipped that alarm that should have happened
    @objc private static func willUpdateIsSkipping(sender: Timer) {
        guard let dictionary = sender.userInfo as? [String: Any],
              let dogId: Int = dictionary[KeyConstant.dogId.rawValue] as? Int,
              let passedReminderId: Int = dictionary[KeyConstant.reminderId.rawValue] as? Int else {
            return
        }
        
        guard let dogManager = MainTabBarViewController.mainTabBarViewController?.dogManager else {
            return
        }
        
        let dog = dogManager.findDog(forDogId: dogId)
        let reminder = dog?.dogReminders.findReminder(forReminderId: passedReminderId)
        
        guard let reminder = reminder else {
            return
        }
        
        if reminder.reminderType == .weekly {
            reminder.weeklyComponents.skippedDate = nil
        }
        else if reminder.reminderType == .monthly {
            reminder.monthlyComponents.skippedDate = nil
        }
        reminder.reminderExecutionBasis = Date()
        
        delegate.didUpdateDogManager(sender: Sender(origin: self, localized: self), forDogManager: dogManager)
        
    }
    
}
