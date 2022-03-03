//
//  Reminder.swift
//  Hound
//
//  Created by Jonathan Xakellis on 11/20/20.
//  Copyright © 2020 Jonathan Xakellis. All rights reserved.
//

import UIKit

/// Enum full of cases of possible errors from ReminderManager
enum ReminderManagerError: Error {
    case reminderIdAlreadyPresent
    case reminderIdNotPresent
}

protocol ReminderManagerProtocol {

    // dog that holds the reminders
    var masterDog: Dog? { get set }

    // array of reminders, a dog should contain one of these to specify all of its reminders
    var reminders: [Reminder] { get }

    /// Checks to see if a reminder is already present. If its reminderId is, then is removes the old one and replaces it with the new
    mutating func addReminder(newReminder: Reminder) throws

    /// Invokes addReminder(newReminder: Reminder) for newReminder.count times
    mutating func addReminder(newReminders: [Reminder]) throws

    /// removes trys to find a reminder whos name (capitals don't matter) matches reminder name given, if found removes reminder, if not found throws error
    mutating func removeReminder(forReminderId reminderId: Int) throws
    mutating func removeReminder(forIndex index: Int)

    /// Removed as addReminer can serve this purpose (replaces old one if already present)
    // mutating func changeReminder(forReminderId reminderId: String, newReminder: Reminder) throws

    /// finds and returns the reference of a reminder matching the given reminderId
    func findReminder(forReminderId reminderId: Int) throws -> Reminder

    /// finds and returns the index of a reminder with a reminderId in terms of the reminder: [Reminder] array
    func findIndex(forReminderId reminderId: Int) throws -> Int

}

extension ReminderManagerProtocol {

    func findReminder(forReminderId reminderId: Int) throws -> Reminder {

        for r in 0..<reminders.count where reminders[r].reminderId == reminderId {
            return reminders[r]
        }
        throw ReminderManagerError.reminderIdNotPresent
    }

    func findIndex(forReminderId reminderId: Int) throws -> Int {
        for r in 0..<reminders.count where reminders[r].reminderId == reminderId {
            return r
        }
        throw ReminderManagerError.reminderIdNotPresent
    }

}

class ReminderManager: NSObject, NSCoding, NSCopying, ReminderManagerProtocol {

    // MARK: - NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = ReminderManager(masterDog: masterDog, initReminders: self.reminders)
        return copy
    }

    // MARK: - NSCoding
    required init?(coder aDecoder: NSCoder) {
        storedReminders = aDecoder.decodeObject(forKey: "reminders") as? [Reminder] ?? aDecoder.decodeObject(forKey: "requirements") as? [Reminder] ?? aDecoder.decodeObject(forKey: "requirments") as? [Reminder] ?? []
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(storedReminders, forKey: "reminders")
    }

    // static var supportsSecureCoding: Bool = true

    init(masterDog: Dog?, initReminders: [Reminder] = []) {
        self.storedMasterDog = masterDog
        super.init()
        for reminder in initReminders {
            appendReminder(newReminder: reminder)
        }
    }

    private var storedMasterDog: Dog?

    var masterDog: Dog? {
        get {
            return storedMasterDog
        }
        set (newMasterDog) {
            self.storedMasterDog = newMasterDog
            for reminder in storedReminders {
                reminder.masterDog = storedMasterDog
            }
        }
    }

    /// Array of reminders
    private var storedReminders: [Reminder] = []
    var reminders: [Reminder] { return storedReminders }

    /// This handles the proper appending of a reminder. This function assumes an already checked reminder and its purpose is to bypass the add reminder endpoint
    private func appendReminder(newReminder: Reminder) {
        let newReminderCopy = newReminder.copy() as! Reminder
        newReminderCopy.masterDog = self.masterDog
       storedReminders.append(newReminderCopy)
    }

    func addReminder(newReminder: Reminder) throws {

        // Index of the reminder, nil if it isn't present and not nil if it already exists. A non nil value means we replace the reminder and a nil value means we simply add
        var reminderIndex: Int?
        for i in 0..<reminders.count where reminders[i].reminderId == newReminder.reminderId {
            reminderIndex = i
            break
        }

        if reminderIndex != nil {
            // instead of crashing, replace the reminder.
            storedReminders[reminderIndex!].timer?.invalidate()
            storedReminders[reminderIndex!] = newReminder
            AppDelegate.endpointLogger.notice("ENDPOINT Update Reminder")
        }
        else {
            // adding new, not replacing
            appendReminder(newReminder: newReminder)
            AppDelegate.endpointLogger.notice("ENDPOINT Add Reminder")
        }

        sortReminders()
    }

    func addReminder(newReminders: [Reminder]) throws {
        for reminder in newReminders {
            try addReminder(newReminder: reminder)
        }
        sortReminders()
    }

    func removeReminder(forReminderId reminderId: Int) throws {
        var reminderNotPresent = true

        // goes through reminders to see if the given reminder name (aka reminder name) is in the array of reminders
        for reminder in reminders where reminder.reminderId == reminderId {
            reminderNotPresent = false
            break
        }

        // if provided reminder is not present, throws error

        if reminderNotPresent == true {
            throw ReminderManagerError.reminderIdNotPresent
        }
        // if provided reminder is present, proceeds
        else {
            // finds index of given reminder (through reminder name), returns nil if not found but it should be if code is written correctly, code should not be not be able to reach this point if reminder name was not present
            var indexOfRemovalTarget: Int? {
                for index in 0...Int(reminders.count) where reminders[index].reminderId == reminderId {
                    return index
                }
                return nil
            }

        storedReminders[indexOfRemovalTarget ?? -1].timer?.invalidate()
        storedReminders.remove(at: indexOfRemovalTarget ?? -1)
        AppDelegate.endpointLogger.notice("ENDPOINT Remove Reminder (via reminderId)")
        }
    }

    func removeReminder(forIndex index: Int) {
        storedReminders[index].timer?.invalidate()
        storedReminders.remove(at: index)
        AppDelegate.endpointLogger.notice("ENDPOINT Remove Reminder (via index)")
    }

    /// adds default set of reminders
    func addDefaultReminders() {
        try! addReminder(newReminder: ReminderConstant.defaultReminderOne)
        try! addReminder(newReminder: ReminderConstant.defaultReminderTwo)
        try! addReminder(newReminder: ReminderConstant.defaultReminderThree)
        try! addReminder(newReminder: ReminderConstant.defaultReminderFour)
    }

    /*
     func changeReminder(forReminderId reminderId: String, newReminder: Reminder) throws {
         
         //check to find the index of targetted reminder
         var newReminderIndex: Int?
         
         for i in 0..<reminders.count {
             if reminders[i].reminderId == reminderId {
                 newReminderIndex = i
             }
         }
         
         if newReminderIndex == nil {
             throw ReminderManagerError.reminderUUIDNotPresent
         }
         
         else {
             newReminder.masterDog = self.masterDog
             storedReminders[newReminderIndex!] = newReminder
             AppDelegate.endpointLogger.notice("ENDPOINT Update Reminder (trait)")
         }
         sortReminders()
     }
     */

    private func sortReminders() {
    storedReminders.sort { (reminder1, reminder2) -> Bool in
        if reminder1.timingStyle == .oneTime && reminder2.timingStyle == .oneTime {
            if Date().distance(to: reminder1.oneTimeComponents.executionDate!) < Date().distance(to: reminder2.oneTimeComponents.executionDate!) {
                return true
            }
            else {
                return false
            }
        }
        // both countdown
        else if reminder1.timingStyle == .countDown && reminder2.timingStyle == .countDown {
            // shorter is listed first
            if reminder1.countDownComponents.executionInterval <= reminder2.countDownComponents.executionInterval {
                return true
            }
            else {
                return false
            }
        }
        // both weekly
        else if reminder1.timingStyle == .weekly && reminder2.timingStyle == .weekly {
            // earlier in the day is listed first
            let reminder1Hour = reminder1.timeOfDayComponents.timeOfDayComponent.hour!
            let reminder2Hour = reminder2.timeOfDayComponents.timeOfDayComponent.hour!
            if reminder1Hour == reminder2Hour {
                let reminder1Minute = reminder1.timeOfDayComponents.timeOfDayComponent.minute!
                let reminder2Minute = reminder2.timeOfDayComponents.timeOfDayComponent.minute!
                if reminder1Minute <= reminder2Minute {
                    return true
                }
                else {
                    return false
                }
            }
            else if reminder1Hour <= reminder2Hour {
                return true
            }
            else {
                return false
            }
        }
        // both monthly
        else if reminder1.timingStyle == .monthly && reminder2.timingStyle == .monthly {
            let reminder1Day: Int! = reminder1.timeOfDayComponents.dayOfMonth
            let reminder2Day: Int! = reminder2.timeOfDayComponents.dayOfMonth
            // first day of the month comes first
            if reminder1Day == reminder2Day {
                // earliest in day comes first if same days
                let reminder1Hour = reminder1.timeOfDayComponents.timeOfDayComponent.hour!
                let reminder2Hour = reminder2.timeOfDayComponents.timeOfDayComponent.hour!
                if reminder1Hour == reminder2Hour {
                // earliest in hour comes first if same hour
                    let reminder1Minute = reminder1.timeOfDayComponents.timeOfDayComponent.minute!
                    let reminder2Minute = reminder2.timeOfDayComponents.timeOfDayComponent.minute!
                    if reminder1Minute <= reminder2Minute {
                        return true
                    }
                    else {
                        return false
                    }
                }
                else if reminder1Hour <= reminder2Hour {
                    return true
                }
                else {
                    return false
                }
            }
            else if reminder1Day < reminder2Day {
                return true
            }
            else {
                return false
            }
        }
        // different timing styles
        else {

            // reminder1 and reminder2 are known to be different styles
            switch reminder1.timingStyle {
            case .countDown:
                // can assume is comes first as countdown always first and different
                return true
            case .weekly:
                if reminder2.timingStyle == .countDown {
                    return false
                }
                else {
                    return true
                }
            case .monthly:
                if reminder2.timingStyle == .oneTime {
                    return true
                }
                else {
                    return false
                }
            case .oneTime:
                return false
            }

        }
    }
}

}

protocol ReminderManagerControlFlowProtocol {

    /// Returns a copy of ReminderManager used to avoid accidental changes (due to reference type) by classes which get their dog manager from here
    func getReminderManager() -> ReminderManager

    /// Sets reminderManager equal to newReminderManager, depending on sender will also call methods to propogate change.
    func setReminderManager(sender: Sender, newReminderManager: ReminderManager)

    // Updates things dependent on reminderManager
    func updateReminderManagerDependents()

}
