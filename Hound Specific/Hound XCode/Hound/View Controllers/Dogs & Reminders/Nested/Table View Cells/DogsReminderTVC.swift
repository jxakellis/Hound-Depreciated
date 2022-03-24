//
//  DogsReminderTableViewCell.swift
//  Hound
//
//  Created by Jonathan Xakellis on 1/20/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import UIKit

protocol DogsReminderTableViewCellDelegate: AnyObject {
    /// The reminder switch to toggle the enable status was flipped. The reminder was updated and the server queried.
    func didUpdateReminderEnable(sender: Sender, parentDogId: Int, reminder: Reminder)
}

class DogsReminderTableViewCell: UITableViewCell {

    // MARK: - IB

    @IBOutlet private weak var reminderDisplay: UILabel!
    @IBOutlet private weak var reminderToggleSwitch: UISwitch!

    @IBAction func didToggleEnable(_ sender: Any) {
        reminder.isEnabled = reminderToggleSwitch.isOn
        delegate.didUpdateReminderEnable(sender: Sender(origin: self, localized: self), parentDogId: parentDogId, reminder: reminder)
        
        RemindersRequest.update(forDogId: parentDogId, forReminder: reminder) { requestWasSuccessful in
            if requestWasSuccessful == false {
                self.reminderToggleSwitch.setOn(false, animated: true)
                self.reminder.isEnabled = self.reminderToggleSwitch.isOn
                self.delegate.didUpdateReminderEnable(sender: Sender(origin: self, localized: self), parentDogId: self.parentDogId, reminder: self.reminder)
            }
        }
    }

    // MARK: - Properties

    weak var delegate: DogsReminderTableViewCellDelegate! = nil
    
    var parentDogId: Int! = nil

    var reminder: Reminder! = nil

    // MARK: - Main

    // when cell is awoken / init, this is executed
    override func awakeFromNib() {
        super.awakeFromNib()
        reminderDisplay.adjustsFontSizeToFitWidth = true

        // self.contentMode = .center
        // self.imageView?.contentMode = .center
    }

    func setup(parentDogId: Int, forReminder reminderPassed: Reminder) {
        self.parentDogId = parentDogId
        reminder = reminderPassed

        reminderDisplay.text = ""

        if reminder.reminderType == .oneTime {
            self.reminderDisplay.text? = " \(String.convertToReadable(fromDate: reminder.oneTimeComponents.executionDate))"
        }
        else if reminder.reminderType == .countdown {
            self.reminderDisplay.text?.append(" Every \(String.convertToReadable(fromTimeInterval: reminder.countdownComponents.executionInterval))")
        }
        else if reminder.reminderType == .monthly {

                let dayOfMonth: Int! = reminder.monthlyComponents.dayOfMonth
                reminderDisplay.text?.append(" Every Month on \(dayOfMonth!)")

                reminderDisplay.text?.append(String.dayOfMonthSuffix(day: dayOfMonth))

        }
        else if reminder.reminderType == .weekly {

            try! self.reminderDisplay.text?.append(" \(String.convertToReadable(fromDateComponents: reminder.weeklyComponents.dateComponents))")

            // weekdays
            if reminder.weeklyComponents.weekdays == [1, 2, 3, 4, 5, 6, 7] {
                reminderDisplay.text?.append(" Everyday")
            }
            else if reminder.weeklyComponents.weekdays == [1, 7] {
                reminderDisplay.text?.append(" on Weekends")
            }
            else if reminder.weeklyComponents.weekdays == [2, 3, 4, 5, 6] {
                reminderDisplay.text?.append(" on Weekdays")
            }
            else {
                reminderDisplay.text?.append(" on")
                if reminder.weeklyComponents.weekdays.count == 1 {
                    for weekdayInt in reminder.weeklyComponents.weekdays {
                        switch weekdayInt {
                        case 1:
                            reminderDisplay.text?.append(" Sunday")
                        case 2:
                            reminderDisplay.text?.append(" Monday")
                        case 3:
                            reminderDisplay.text?.append(" Tuesday")
                        case 4:
                            reminderDisplay.text?.append(" Wednesday")
                        case 5:
                            reminderDisplay.text?.append(" Thursday")
                        case 6:
                            reminderDisplay.text?.append(" Friday")
                        case 7:
                            reminderDisplay.text?.append(" Saturday")
                        default:
                            reminderDisplay.text?.append("unknown")
                        }
                    }
                }
                else {
                    for weekdayInt in reminder.weeklyComponents.weekdays {
                        switch weekdayInt {
                        case 1:
                            reminderDisplay.text?.append(" Su,")
                        case 2:
                            reminderDisplay.text?.append(" M,")
                        case 3:
                            reminderDisplay.text?.append(" Tu,")
                        case 4:
                            reminderDisplay.text?.append(" W,")
                        case 5:
                            reminderDisplay.text?.append(" Th,")
                        case 6:
                            reminderDisplay.text?.append(" F,")
                        case 7:
                            reminderDisplay.text?.append(" Sa,")
                        default:
                            reminderDisplay.text?.append("unknown")
                        }
                    }
                }
                // checks if extra comma, then removes
                if reminderDisplay.text?.last == ","{
                    reminderDisplay.text?.removeLast()
                }
            }
        }

        reminderDisplay.attributedText = reminderDisplay.text?.addingFontToBeginning(text: reminder.displayTypeName + " -", font: UIFont.systemFont(ofSize: reminderDisplay.font.pointSize, weight: .medium))

        self.reminderToggleSwitch.isOn = reminder.isEnabled

    }

}
