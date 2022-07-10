//
//  DogsReminderManagerViewController.swift
//  Hound
//
//  Created by Jonathan Xakellis on 3/28/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import UIKit

/*
 protocol DogsReminderManagerViewControllerDelegate: AnyObject {
 func didAddReminder(newReminder: Reminder)
 func didUpdateReminder(updatedReminder: Reminder)
 }
 */

class DogsReminderManagerViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate, DogsReminderCountdownViewControllerDelegate, DogsReminderWeeklyViewControllerDelegate, DropDownUIViewDataSource, DogsReminderMonthlyViewControllerDelegate, DogsReminderOneTimeViewControllerDelegate {
    
    // MARK: Auto Save Trigger
    
    // MARK: - DogsReminderCountdownViewControllerDelegate and DogsReminderWeeklyViewControllerDelegate
    
    func willDismissKeyboard() {
        dismissKeyboard()
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    // MARK: - DropDownUIViewDataSource
    
    func setupCellForDropDown(cell: UITableViewCell, indexPath: IndexPath, dropDownUIViewIdentifier: String) {
        let customCell = cell as! DropDownTableViewCell
        customCell.adjustLeadingTrailing(newConstant: DropDownUIView.insetForBorderedUILabel)
        
        if selectedIndexPath == indexPath {
            customCell.willToggleDropDownSelection(forSelected: true)
        }
        else {
            customCell.willToggleDropDownSelection(forSelected: false)
        }
        
        // inside of the predefined ReminderAction
        if indexPath.row < ReminderAction.allCases.count {
            customCell.label.text = ReminderAction.allCases[indexPath.row].displayActionName(reminderCustomActionName: nil, isShowingAbreviatedCustomActionName: false)
        }
        // a user generated custom name
        else {
            customCell.label.text = ReminderAction.custom.displayActionName(reminderCustomActionName: LocalConfiguration.reminderCustomActionNames[indexPath.row - ReminderAction.allCases.count], isShowingAbreviatedCustomActionName: false)
        }
    }
    
    func numberOfRows(forSection: Int, dropDownUIViewIdentifier: String) -> Int {
        return ReminderAction.allCases.count + LocalConfiguration.reminderCustomActionNames.count
    }
    
    func numberOfSections(dropDownUIViewIdentifier: String) -> Int {
        return 1
    }
    
    func selectItemInDropDown(indexPath: IndexPath, dropDownUIViewIdentifier: String) {
        
        let selectedCell = dropDown.dropDownTableView!.cellForRow(at: indexPath) as! DropDownTableViewCell
        selectedCell.willToggleDropDownSelection(forSelected: true)
        selectedIndexPath = indexPath
        
        // inside of the predefined LogAction
        if indexPath.row < ReminderAction.allCases.count {
            reminderActionLabel.text = ReminderAction.allCases[indexPath.row].displayActionName(reminderCustomActionName: nil, isShowingAbreviatedCustomActionName: false)
            selectedReminderAction = ReminderAction.allCases[indexPath.row]
        }
        // a user generated custom name
        else {
            reminderActionLabel.text = ReminderAction.custom.displayActionName(reminderCustomActionName: LocalConfiguration.reminderCustomActionNames[indexPath.row - ReminderAction.allCases.count], isShowingAbreviatedCustomActionName: false)
            selectedReminderAction = ReminderAction.custom
            reminderCustomActionNameTextField.text = LocalConfiguration.reminderCustomActionNames[indexPath.row - ReminderAction.allCases.count]
        }
        
        dismissKeyboardAndDropDown()
        
        // "Custom" is the last item in ReminderAction
        if indexPath.row < ReminderAction.allCases.count - 1 {
            toggleReminderCustomActionNameTextField(isHidden: true)
        }
        else {
            // if reminder action is custom, then it doesn't hide the special input fields.
            toggleReminderCustomActionNameTextField(isHidden: false)
        }
        
    }
    
    // MARK: - IB
    
    @IBOutlet private weak var containerForAll: UIView!
    
    @IBOutlet private weak var onceContainerView: UIView!
    @IBOutlet private weak var countdownContainerView: UIView!
    @IBOutlet private weak var weeklyContainerView: UIView!
    @IBOutlet private weak var monthlyContainerView: UIView!
    
    @IBOutlet private weak var reminderActionLabel: BorderedUILabel!
    
    /// Text input for customLogActionName
    @IBOutlet private weak var reminderCustomActionNameTextField: BorderedUITextField!
    @IBOutlet private weak var reminderCustomActionNameHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var reminderCustomActionNameBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var reminderIsEnabledSwitch: UISwitch!
    
    @IBOutlet weak var reminderTypeSegmentedControl: UISegmentedControl!
    
    @IBAction private func didUpdateReminderType(_ sender: UISegmentedControl) {
        onceContainerView.isHidden = !(sender.selectedSegmentIndex == 0)
        countdownContainerView.isHidden = !(sender.selectedSegmentIndex == 1)
        weeklyContainerView.isHidden = !(sender.selectedSegmentIndex == 2)
        monthlyContainerView.isHidden = !(sender.selectedSegmentIndex == 3)
    }
    
    // MARK: - Properties
    
    var targetReminder: Reminder?
    
    private var dogsReminderOneTimeViewController = DogsReminderOneTimeViewController()
    
    private var dogsReminderCountdownViewController = DogsReminderCountdownViewController()
    
    private var dogsReminderWeeklyViewController = DogsReminderWeeklyViewController()
    
    private var dogsReminderMonthlyViewController = DogsReminderMonthlyViewController()
    
    private var initalReminderAction: ReminderAction!
    private var initalReminderCustomActionName: String?
    private var initalReminderIsEnabled: Bool!
    private var initalReminderTypeSegmentedControlIndex: Int!
    
    var initalValuesChanged: Bool {
        if initalReminderAction != selectedReminderAction {
            return true
        }
        else if selectedReminderAction == ReminderAction.custom && initalReminderCustomActionName != reminderCustomActionNameTextField.text {
            return true
        }
        else if initalReminderIsEnabled != reminderIsEnabledSwitch.isOn {
            return true
        }
        else if initalReminderTypeSegmentedControlIndex != reminderTypeSegmentedControl.selectedSegmentIndex {
            return true
        }
        else {
            switch reminderTypeSegmentedControl.selectedSegmentIndex {
            case 0:
                return dogsReminderOneTimeViewController.initalValuesChanged
            case 1:
                return dogsReminderCountdownViewController.initalValuesChanged
            case 2:
                return dogsReminderWeeklyViewController.initalValuesChanged
            case 3:
                return dogsReminderMonthlyViewController.initalValuesChanged
            default:
                return false
            }
        }
    }
    
    private let dropDown = DropDownUIView()
    
    private var selectedIndexPath: IndexPath?
    var selectedReminderAction: ReminderAction?
    
    // MARK: - Main
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        oneTimeSetup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        repeatableSetup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dropDown.hideDropDown(removeFromSuperview: true)
    }
    
    // MARK: - Setup
    
    private func oneTimeSetup() {
        setupValues()
        setupGestures()
        setupSegmentedControl()
        
        /// Sets up the values of different variables that is found out from information passed
        func setupValues() {
            
            if targetReminder != nil {
                selectedIndexPath = IndexPath(row: ReminderAction.allCases.firstIndex(of: targetReminder!.reminderAction)!, section: 0)
            }
            
            if let targetReminder = targetReminder {
                // this is for the label for the reminderAction dropdown, so we only want the names to be the defaults. I.e. if our reminder is "Custom" with "someCustomActionName", the reminderActionLabel should only show "Custom" and then the logCustomActionNameTextField should be "someCustomActionName".
                reminderActionLabel.text = targetReminder.reminderAction.displayActionName(reminderCustomActionName: nil, isShowingAbreviatedCustomActionName: false)
            }
            else {
                reminderActionLabel.text = ""
            }
            reminderActionLabel.placeholder = "Select an action..."
            selectedReminderAction = targetReminder?.reminderAction
            
            initalReminderAction = targetReminder?.reminderAction
            
            reminderCustomActionNameTextField.text = targetReminder?.reminderCustomActionName
            reminderCustomActionNameTextField.placeholder = " Enter a custom action name..."
            reminderCustomActionNameTextField.delegate = self
            
            initalReminderCustomActionName = reminderCustomActionNameTextField.text
            // if == is true, that means it is custom, which means it shouldn't hide so ! reverses to input isHidden: false, reverse for if type is not custom. This is because this text input field is only used for custom types.
            toggleReminderCustomActionNameTextField(isHidden: !(targetReminder?.reminderAction == .custom))
            
            reminderIsEnabledSwitch.isOn = targetReminder?.reminderIsEnabled ?? ReminderConstant.defaultReminderIsEnabled
            
            initalReminderIsEnabled = targetReminder?.reminderIsEnabled ?? ReminderConstant.defaultReminderIsEnabled
        }
        
        /// Sets up gestureRecognizer for dog selector drop down
        func setupGestures() {
            reminderActionLabel.isUserInteractionEnabled = true
            let reminderActionTapGesture = UITapGestureRecognizer(target: self, action: #selector(reminderActionTapped))
            reminderActionTapGesture.delegate = self
            reminderActionTapGesture.cancelsTouchesInView = false
            reminderActionLabel.addGestureRecognizer(reminderActionTapGesture)
            
            let dismissKeyboardAndDropDownTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardAndDropDown))
            dismissKeyboardAndDropDownTapGesture.delegate = self
            dismissKeyboardAndDropDownTapGesture.cancelsTouchesInView = false
            containerForAll.addGestureRecognizer(dismissKeyboardAndDropDownTapGesture)
        }
        
        func setupSegmentedControl() {
            reminderTypeSegmentedControl.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.white], for: .normal)
            reminderTypeSegmentedControl.backgroundColor = .systemGray4
            
            onceContainerView.isHidden = true
            countdownContainerView.isHidden = true
            weeklyContainerView.isHidden = true
            monthlyContainerView.isHidden = true
            
            // creating new
            if targetReminder == nil {
                reminderTypeSegmentedControl.selectedSegmentIndex = 1
                countdownContainerView.isHidden = false
            }
            // editing current
            else {
                if targetReminder!.reminderType == .oneTime {
                    reminderTypeSegmentedControl.selectedSegmentIndex = 0
                    onceContainerView.isHidden = false
                }
                // Segmented control setup
                else if targetReminder!.reminderType == .countdown {
                    reminderTypeSegmentedControl.selectedSegmentIndex = 1
                    countdownContainerView.isHidden = false
                }
                else if targetReminder!.reminderType == .weekly {
                    reminderTypeSegmentedControl.selectedSegmentIndex = 2
                    weeklyContainerView.isHidden = false
                }
                else {
                    reminderTypeSegmentedControl.selectedSegmentIndex = 3
                    monthlyContainerView.isHidden = false
                }
            }
            
            // assign value to inital parameter
            initalReminderTypeSegmentedControlIndex = reminderTypeSegmentedControl.selectedSegmentIndex
        }
    }
    
    private func repeatableSetup () {
        setupDropDown()
        func setupDropDown() {
            /// only one dropdown used on the dropdown instance so no identifier needed
            dropDown.dropDownUIViewIdentifier = ""
            dropDown.cellReusableIdentifier = "dropDownCell"
            dropDown.dataSource = self
            dropDown.setUpDropDown(viewPositionReference: reminderActionLabel.frame, offset: 2.0)
            dropDown.nib = UINib(nibName: "DropDownTableViewCell", bundle: nil)
            dropDown.setRowHeight(height: DropDownUIView.rowHeightForBorderedUILabel)
            view.addSubview(dropDown)
        }
    }
    
    // MARK: - Functions
    
    /// Attempts to either create a new reminder or update an existing reminder from the settings chosen by the user. If there are invalid settings (e.g. no weekdays), an error message is sent to the user and nil is returned. If the reminder is valid, a reminder is returned that is ready to be sent to the server.
    func applyReminderSettings() -> Reminder? {
        do {
            guard selectedReminderAction != nil else {
               throw ReminderActionError.blankReminderAction
            }
            
            let reminder: Reminder!
            if targetReminder != nil {
                reminder = targetReminder!.copy() as? Reminder
            }
            else {
                reminder = Reminder()
            }
            
            reminder.reminderId = targetReminder?.reminderId ?? reminder.reminderId
            reminder.reminderAction = selectedReminderAction!
            
            if selectedReminderAction == ReminderAction.custom {
                let trimmedReminderCustomActionName = reminderCustomActionNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                // if the trimmedReminderCustomActionName is not "", meaning it has text, then we save it. Otherwise, the trimmedReminderCustomActionName is "" or nil so we save its value as nil
                reminder.reminderCustomActionName = (trimmedReminderCustomActionName != "") ? trimmedReminderCustomActionName : nil
            }
            reminder.reminderIsEnabled = reminderIsEnabledSwitch.isOn
            
            switch reminderTypeSegmentedControl.selectedSegmentIndex {
            case 0:
                reminder.reminderType = .oneTime
                
                reminder.oneTimeComponents.oneTimeDate = dogsReminderOneTimeViewController.oneTimeDate
            case 1:
                reminder.reminderType = .countdown
                
                reminder.countdownComponents.intervalElapsed = dogsReminderCountdownViewController.countdown.countDownDuration
            case 2:
                let weekdays = dogsReminderWeeklyViewController.weekdays
                if weekdays == nil {
                    throw WeeklyComponentsError.weekdayArrayInvalid
                }
                reminder.reminderType = .weekly
                
                try reminder.weeklyComponents.changeWeekdays(newWeekdays: weekdays!)
                try reminder.weeklyComponents.changeHour(newHour: Calendar.current.component(.hour, from: dogsReminderWeeklyViewController.timeOfDayDatePicker.date))
                try reminder.weeklyComponents.changeMinute(newMinute: Calendar.current.component(.minute, from: dogsReminderWeeklyViewController.timeOfDayDatePicker.date))
            case 3:
                reminder.reminderType = .monthly
                try reminder.monthlyComponents.changeDay(newDay: Calendar.current.component(.day, from: dogsReminderMonthlyViewController.timeOfDayDatePicker.date))
                try reminder.monthlyComponents.changeHour(newHour: Calendar.current.component(.hour, from: dogsReminderMonthlyViewController.timeOfDayDatePicker.date))
                try reminder.monthlyComponents.changeMinute(newMinute: Calendar.current.component(.minute, from: dogsReminderMonthlyViewController.timeOfDayDatePicker.date))
            default: break
            }
            
            // updating an existing reminder
            if targetReminder != nil {
                // Checks for differences in time of day, execution interval, weekdays, or time of month. If one is detected then we reset the reminder's whole timing to default
                // If you were 5 minutes in to a 1 hour countdown but then change it to 30 minutes, you would want to be 0 minutes into the new timer and not 5 minutes in like previously.
                
                switch reminder.reminderType {
                case .oneTime:
                    // execution date changed
                    if reminder.oneTimeComponents.oneTimeDate != targetReminder!.oneTimeComponents.oneTimeDate {
                        reminder.prepareForNextAlarm()
                    }
                case .countdown:
                    // execution interval changed
                    if reminder.countdownComponents.executionInterval != targetReminder!.countdownComponents.executionInterval {
                        reminder.prepareForNextAlarm()
                    }
                case .weekly:
                    // time of day or weekdays changed
                    if reminder.weeklyComponents.weekdays != targetReminder!.weeklyComponents.weekdays || reminder.weeklyComponents.hour != targetReminder!.weeklyComponents.hour || reminder.weeklyComponents.minute != targetReminder!.weeklyComponents.minute {
                        reminder.prepareForNextAlarm()
                    }
                case .monthly:
                    // time of day or day of month changed
                    if reminder.monthlyComponents.day != targetReminder!.monthlyComponents.day || reminder.monthlyComponents.hour != targetReminder!.monthlyComponents.hour || reminder.monthlyComponents.minute != targetReminder!.monthlyComponents.minute {
                        reminder.prepareForNextAlarm()
                    }
                }
            }
            
            return reminder
        }
        catch {
            ErrorManager.alert(forError: error)
            return nil
        }
    }
    
    /// Toggles visability of optional custom log type components, used for a custom name for it
    private func toggleReminderCustomActionNameTextField(isHidden: Bool) {
        if isHidden == false {
            reminderCustomActionNameHeightConstraint.constant = 40.0
            reminderCustomActionNameBottomConstraint.constant = 10.0
            reminderCustomActionNameTextField.isHidden = false
            
        }
        else {
            reminderCustomActionNameHeightConstraint.constant = 0.0
            reminderCustomActionNameBottomConstraint.constant = 0.0
            reminderCustomActionNameTextField.isHidden = true
        }
        containerForAll.setNeedsLayout()
        containerForAll.layoutIfNeeded()
    }
    
    // MARK: - @objc
    
    @objc private func reminderActionTapped() {
        dismissKeyboard()
        dropDown.showDropDown(numberOfRowsToShow: 6.5, selectedIndexPath: selectedIndexPath)
    }
    
    @objc internal override func dismissKeyboard() {
        super.dismissKeyboard()
        if  MainTabBarViewController.mainTabBarViewController.dogsViewController.navigationController?.topViewController !=  nil && MainTabBarViewController.mainTabBarViewController.dogsViewController.navigationController!.topViewController! is DogsAddDogViewController {
            MainTabBarViewController.mainTabBarViewController.dogsViewController.navigationController!.topViewController!.dismissKeyboard()
        }
    }
    
    @objc private func dismissKeyboardAndDropDown() {
        dismissKeyboard()
        dropDown.hideDropDown()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Guard statements are used so that information is only passed to the VC thats the reminder's current type.
        //  This is so the current menu (e.g. weekly) has the up to date information but the other ones (e.g. countdown, monthly, oneTime) are in the default statement (e.g. datePickers set to current date and time).
        // If we didn't do this, the defaults that were applied to the countdown/monthly/oneTime components a while ago would be passed (e.g. date pickers set to 7:00am on some day that isn't the current one). But with these guard statements, the everything is configured so it reflects the present moment (e.g. datePickers set to current time and current day)
        
        if segue.identifier == "dogsReminderCountdownViewController"{
            dogsReminderCountdownViewController = segue.destination as! DogsReminderCountdownViewController
            dogsReminderCountdownViewController.delegate = self
            
            guard targetReminder != nil && targetReminder!.reminderType == .countdown else {
                return
            }
            
            dogsReminderCountdownViewController.passedInterval = targetReminder!.countdownComponents.executionInterval
            
        }
        else if segue.identifier == "dogsReminderWeeklyViewController"{
            dogsReminderWeeklyViewController = segue.destination as! DogsReminderWeeklyViewController
            dogsReminderWeeklyViewController.delegate = self
            
            guard targetReminder != nil && targetReminder!.reminderType == .weekly else {
                return
            }
                dogsReminderWeeklyViewController.passedTimeOfDay = targetReminder!.weeklyComponents.notSkippingExecutionDate(reminderExecutionBasis: targetReminder!.reminderExecutionBasis)
                dogsReminderWeeklyViewController.passedWeekDays = targetReminder!.weeklyComponents.weekdays
            
        }
        else if segue.identifier == "dogsReminderMonthlyViewController"{
            dogsReminderMonthlyViewController = segue.destination as! DogsReminderMonthlyViewController
            dogsReminderMonthlyViewController.delegate = self
           
            guard targetReminder != nil && targetReminder!.reminderType == .monthly else {
                return
            }
            
            dogsReminderMonthlyViewController.passedTimeOfDay = targetReminder!.monthlyComponents.notSkippingExecutionDate(reminderExecutionBasis: targetReminder!.reminderExecutionBasis)
        }
        else if segue.identifier == "dogsReminderOneTimeViewController"{
            dogsReminderOneTimeViewController = segue.destination as! DogsReminderOneTimeViewController
            dogsReminderOneTimeViewController.delegate = self
            
            guard targetReminder != nil && targetReminder!.reminderType == .oneTime && Date().distance(to: targetReminder!.oneTimeComponents.oneTimeDate) > 0 else {
                return
            }
            
            dogsReminderOneTimeViewController.passedDate = targetReminder!.oneTimeComponents.oneTimeDate
        }
        
    }
    
}
