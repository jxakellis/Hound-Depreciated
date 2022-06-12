//
//  Timing.swift
//  Hound
//
//  Created by Jonathan Xakellis on 11/20/20.
//  Copyright © 2020 Jonathan Xakellis. All rights reserved.
//

import UIKit

protocol TimingManagerDelegate {
    func didUpdateDogManager(sender: Sender, newDogManager: DogManager)
}

class TimingManager {
    
    // MARK: - Properties
    
    static var delegate: TimingManagerDelegate! = nil
    
    /// If a timeOfDay alarm is being skipped, this array stores all the timers that are responsible for unskipping the alarm when it goes from 1 Day -> 23 Hours 59 Minutes
    private static var isSkippingDisablingTimers: [Timer] = []
    
    // MARK: - Main
    
    /// Initalizes all timers according to the dogManager passed, assumes no timers currently active and if transitioning from Paused to Unpaused (didUnpuase = true) handles logic differently
    static func willInitalize(forDogManager dogManager: DogManager) {
        
        /// Takes a DogManager and potentially a Bool of if all timers were unpaused, goes through the dog manager and finds all enabled reminders under all enabled dogs and sets a timer to fire.
        
        // Makes sure isPaused is false, don't want to instantiate timers when they should be paused
        guard FamilyConfiguration.isPaused == false else {
            return
        }
        
        let sudoDogManager = dogManager
        // goes through all dogs
        for d in 0..<sudoDogManager.dogs.count {
            // makes sure current dog is enabled, as if it isn't then all of its timers arent either
            
            // goes through all reminders in a dog
            for r in 0..<sudoDogManager.dogs[d].dogReminders.reminders.count {
                
                let reminder = sudoDogManager.dogs[d].dogReminders.reminders[r]
                
                // makes sure a reminder is enabled and its presentation is not being handled
                guard reminder.reminderIsEnabled == true && reminder.hasAlarmPresentationHandled == false
                else {
                    continue
                }
                
                // Sets a timer that executes when the timer should go from isSkipping true -> false, e.g. 1 Day left on a timer that is skipping and when it hits 23 hours and 59 minutes it turns into a regular nonskipping timer
                let unskipDate = reminder.unskipDate()
                
                // if the a date to unskip exists, then creates a timer to do so when it is time
                if unskipDate != nil {
                    let isSkippingDisabler = Timer(fireAt: unskipDate!,
                                                   interval: -1,
                                                   target: self,
                                                   selector: #selector(willUpdateIsSkipping(sender:)),
                                                   userInfo: [ServerDefaultKeys.dogId.rawValue: dogManager.dogs[d].dogId, ServerDefaultKeys.reminderId.rawValue: reminder.reminderId],
                                                   repeats: false)
                    
                    isSkippingDisablingTimers.append(isSkippingDisabler)
                    
                    RunLoop.main.add(isSkippingDisabler, forMode: .common)
                }
                
                print(-1)
                let timer = Timer(fireAt: reminder.reminderExecutionDate!,
                                  interval: -1,
                                  target: self,
                                  selector: #selector(self.didExecuteTimer(sender:)),
                                  userInfo: [
                                    ServerDefaultKeys.dogId.rawValue: dogManager.dogs[d].dogId,
                                    ServerDefaultKeys.dogName.rawValue: dogManager.dogs[d].dogName,
                                    ServerDefaultKeys.reminderId.rawValue: reminder.reminderId],
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
    
    /// Used as a selector when constructing timer in willInitalize, when called at an unknown point in time by the timer it triggers helper functions to create both in app notifcations and iOS notifcations
    @objc private static func didExecuteTimer(sender: Timer) {
        
        // Parses the sender info needed to figure out which reminder's timer fired
        guard let parsedDictionary = sender.userInfo as? [String: Any]
        else {
            ErrorManager.alert(forError: TimingManagerError.parseSenderInfoFailed)
            return
        }
        
        let dogName: String = parsedDictionary[ServerDefaultKeys.dogName.rawValue]! as! String
        let dogId: Int = parsedDictionary[ServerDefaultKeys.dogId.rawValue]! as! Int
        let reminderId: Int = parsedDictionary[ServerDefaultKeys.reminderId.rawValue]! as! Int
        
        print(0)
        AlarmManager.willShowAlarm(forDogName: dogName, forDogId: dogId, forReminderId: reminderId)
    }
    
    /// If a reminder is skipping the next time of day alarm, at some point it will go from 1+ day away to 23 hours and 59 minutes. When that happens then the timer should be changed from isSkipping to normal mode because it just skipped that alarm that should have happened
    @objc private static func willUpdateIsSkipping(sender: Timer) {
        guard let parsedDictionary = sender.userInfo as? [String: Any]
        else {
            ErrorManager.alert(forError: TimingManagerError.parseSenderInfoFailed)
            return
        }
        
        let dogId: Int = parsedDictionary[ServerDefaultKeys.dogId.rawValue]! as! Int
        let passedReminderId: Int = parsedDictionary[ServerDefaultKeys.reminderId.rawValue]! as! Int
        let dogManager = MainTabBarViewController.staticDogManager
        
        do {
            let dog = try dogManager.findDog(forDogId: dogId)
            let reminder = try dog.dogReminders.findReminder(forReminderId: passedReminderId)
            
            if reminder.reminderType == .weekly {
                reminder.weeklyComponents.isSkipping = false
                reminder.weeklyComponents.isSkippingDate = nil
            }
            else if reminder.reminderType == .monthly {
                reminder.monthlyComponents.isSkipping = false
                reminder.monthlyComponents.isSkippingDate = nil
                
            }
            reminder.reminderExecutionBasis = Date()
            
            delegate.didUpdateDogManager(sender: Sender(origin: self, localized: self), newDogManager: dogManager)
            
        }
        catch {
            AppDelegate.generalLogger.notice("willUpdateIsSkipping failure in finding dog or reminder")
        }
        
    }
    
}
