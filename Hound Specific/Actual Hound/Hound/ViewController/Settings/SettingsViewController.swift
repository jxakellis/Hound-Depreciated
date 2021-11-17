//
//  SettingsViewController.swift
//  Hound
//
//  Created by Jonathan Xakellis on 2/5/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate {
    func didTogglePause(newPauseState: Bool)
}

class SettingsViewController: UIViewController, ToolTipable {
    
    //MARK: - Logs
    
    //MARK: Dark Mode
    
    @IBOutlet private weak var darkModeSegmentedControl: UISegmentedControl!
    
    @IBAction private func segmentedControl(_ sender: Any) {
        switch darkModeSegmentedControl.selectedSegmentIndex {
        case 0:
            for window in UIApplication.shared.windows{
                window.overrideUserInterfaceStyle = .light
                AppearanceConstant.darkModeStyle = .light
            }
        case 1:
            for window in UIApplication.shared.windows{
                window.overrideUserInterfaceStyle = .dark
                AppearanceConstant.darkModeStyle = .dark
            }
        default:
            for window in UIApplication.shared.windows{
                window.overrideUserInterfaceStyle = .unspecified
                AppearanceConstant.darkModeStyle = .unspecified
            }
        }
    }
    
    //MARK: Logs Overview Mode
    
    @IBOutlet private weak var logsViewModeSegmentedControl: UISegmentedControl!
    
    @IBAction private func didUpdateLogsViewModeSegmentedControl(_ sender: Any) {
        if logsViewModeSegmentedControl.selectedSegmentIndex == 0{
            AppearanceConstant.isCompactView = true
        }
        else {
            AppearanceConstant.isCompactView = false
        }
    }
    
    //MARK: - Reminders
    //MARK: Pause
    ///Switch for pause all timers
    @IBOutlet private weak var pauseToggleSwitch: UISwitch!
    
    ///If the pause all timers switch it triggered, calls thing function
    @IBAction private func didTogglePause(_ sender: Any) {
        self.willHideToolTip()
        delegate.didTogglePause(newPauseState: pauseToggleSwitch.isOn)
    }
    
    ///Synchronizes the isPaused switch enable and isOn variables to reflect that amount of timers active, if non are active then locks user from changing switch
    private func synchronizeIsPaused(){
        
        
        if MainTabBarViewController.staticDogManager.enabledTimersCount == 0{
            TimingManager.isPaused = false
            self.pauseToggleSwitch.isOn = false
            self.pauseToggleSwitch.isEnabled = false
        }
        else {
            pauseToggleSwitch.isOn = TimingManager.isPaused
            self.pauseToggleSwitch.isEnabled = true
        }
    }
    
    //MARK: Snooze
    
    @IBOutlet private weak var snoozeLengthLabel: ScaledUILabel!
    @IBOutlet private weak var snoozeInterval: UIDatePicker!
    
    @IBAction private func didUpdateSnoozeInterval(_ sender: Any) {
        self.willHideToolTip()
        TimerConstant.defaultSnoozeLength = snoozeInterval.countDownDuration
    }
    
    //MARK: - Notifications
    
    @IBOutlet private weak var notificationToggleSwitch: UISwitch!
    
    @IBAction private func didToggleNotificationEnabled(_ sender: Any) {
        self.willHideToolTip()
        
        UNUserNotificationCenter.current().getNotificationSettings { (permission) in
            switch permission.authorizationStatus {
            case .authorized:
                DispatchQueue.main.async {
                    //notications enabled, going from on to off
                    if NotificationConstant.isNotificationEnabled == true {
                        NotificationConstant.isNotificationEnabled = false
                    }
                    //notifications disabled, going from off to on
                    else {
                        NotificationConstant.isNotificationEnabled = true
                    }
                    self.synchronizeNotificationsComponents(animated: true)
                }
            case .denied:
                DispatchQueue.main.async {
                    Utils.willShowAlert(title: "Notifcations Disabled", message: "To enable notifications go to the Settings App -> Notifications -> Hound and enable \"Allow Notifications\"")
                    
                    let switchDisableTimer = Timer(fire: Date().addingTimeInterval(0.22), interval: -1, repeats: false) { Timer in
                        self.synchronizeAllNotificationSwitches(animated: true)
                    }
                    
                    RunLoop.main.add(switchDisableTimer, forMode: .common)
                    
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (isGranted, error) in
                    NotificationConstant.isNotificationAuthorized = isGranted
                    NotificationConstant.isNotificationEnabled = isGranted
                    NotificationConstant.shouldLoudNotification = isGranted
                    NotificationConstant.shouldFollowUp = isGranted
                    
                    
                    DispatchQueue.main.async {
                        self.synchronizeAllNotificationSwitches(animated: true)
                    }
                    
                }
            case .provisional:
                print(".provisional")
            case .ephemeral:
                print(".ephemeral")
            @unknown default:
                print("unknown auth status")
            }
        }
        
        
        
    }
    ///If disconnect between stored and displayed
    func synchronizeAllNotificationSwitches(animated: Bool){
        //If disconnect between stored and displayed
        if notificationToggleSwitch.isOn != NotificationConstant.isNotificationEnabled {
            notificationToggleSwitch.setOn(NotificationConstant.isNotificationEnabled, animated: true)
        }
        self.synchronizeNotificationsComponents(animated: animated)
    }
    
    //MARK: Loud Notifications
    
    
    @IBOutlet private weak var loudNotificationsLabel: ScaledUILabel!
    
    @IBOutlet private weak var loudNotificationsToggleSwitch: UISwitch!
    
    @IBAction private func didToggleLoudNotifications(_ sender: Any) {
        NotificationConstant.shouldLoudNotification = loudNotificationsToggleSwitch.isOn
    }
    
    
    //MARK: Follow Up Notification
    
    @IBOutlet private weak var followUpReminderLabel: ScaledUILabel!
    
    @IBOutlet private weak var followUpToggleSwitch: UISwitch!
    
    @IBAction private func didToggleFollowUp(_ sender: Any) {
        self.willHideToolTip()
        NotificationConstant.shouldFollowUp = followUpToggleSwitch.isOn
    }
    
    private func synchronizeNotificationsComponents(animated: Bool){
        //notifications are enabled
        if NotificationConstant.isNotificationEnabled == true {
            
            loudNotificationsToggleSwitch.isEnabled = true
            loudNotificationsToggleSwitch.setOn(NotificationConstant.shouldLoudNotification, animated: animated)
            
            followUpToggleSwitch.isEnabled = true
            followUpToggleSwitch.setOn(NotificationConstant.shouldFollowUp, animated: animated)
            
            followUpDelayInterval.isEnabled = true
        }
        //notifications are disabled
        else {
            loudNotificationsToggleSwitch.isEnabled = false
            loudNotificationsToggleSwitch.setOn(false, animated: animated)
            NotificationConstant.shouldLoudNotification = false
            
            followUpToggleSwitch.isEnabled = false
            followUpToggleSwitch.setOn(false, animated: animated)
            NotificationConstant.shouldFollowUp = false
            
            followUpDelayInterval.isEnabled = false
        }
    }
    
    //MARK: Follow Up Delay
    
    @IBOutlet weak var followUpDelayInterval: UIDatePicker!
    
    @IBAction private func didUpdateFollowUpDelay(_ sender: Any) {
        self.willHideToolTip()
        NotificationConstant.followUpDelay = followUpDelayInterval.countDownDuration
    }
    
    //MARK: - App Info
    
    @IBOutlet private weak var buildNumber: ScaledUILabel!
    //MARK: - Tool Tips
    
    //MARK: Follow Up Tool Tip
    
    @IBOutlet private weak var followUpNotificationToolTip: UIButton!
    
    @IBAction private func didClickFollowUpNotificationToolTip(_ sender: Any) {
        followUpNotificationToolTip.isUserInteractionEnabled = false
        
        //followUpNotificationToolTip tool tip is shown
        if toolTipViews[0] != nil {
            hideToolTip(targetTipView: toolTipViews[0]) {
                self.followUpNotificationToolTip.isUserInteractionEnabled = true
            }
        }
        //needs to show followUpNotificationToolTip
        else {
            showToolTip(sourceButton: followUpNotificationToolTip, message: "Sends a follow up \nnotification if you don't\nrespond to the first one.")
            //"Sends a follow up \nnotification if the first one\nis not responded to"
        }
    }
    
    //MARK: Pause All Reminders Tool Tip
    
    @IBOutlet private weak var pauseAllRemindersToolTip: UIButton!
    
    @IBAction private func didClickPauseAllRemindersToolTip(_ sender: Any) {
        
        pauseAllRemindersToolTip.isUserInteractionEnabled = false
        
        //pauseAllRemindersToolTip tool tip shown
        if toolTipViews[2] != nil {
            hideToolTip(targetTipView: toolTipViews[2]) {
                self.pauseAllRemindersToolTip.isUserInteractionEnabled = true
            }
        }
        //needs to show pauseAllRemindersToolTip
        else {
            showToolTip(sourceButton: pauseAllRemindersToolTip, message: "Freezes all reminders\nso they do not\ncountdown or send\nnotifications.")
            //"Sends a follow up \nnotification if the first one\nis not responded to"
        }
    }
    
    //MARK: Snooze Tool Tip
    
    @IBOutlet private weak var snoozeLengthToolTip: UIButton!
    
    @IBAction private func didClickSnoozeLengthToolTip(_ sender: Any) {
        
        snoozeLengthToolTip.isUserInteractionEnabled = false
        
        //snoozeLengthToolTip tool tip shown
        if toolTipViews[1] != nil {
            hideToolTip(targetTipView: toolTipViews[1]) {
                self.snoozeLengthToolTip.isUserInteractionEnabled = true
            }
        }
        //needs to show snoozeLengthToolTip
        else {
            showToolTip(sourceButton: snoozeLengthToolTip, message: "If an alarm is snoozed,\nthis is the length of time\nuntil it sounds again.")
            //"Sends a follow up \nnotification if the first one\nis not responded to"
        }
    }
    
    //MARK: Loud Notifications Tool Tip
    @IBOutlet private weak var loudNotificationsToolTip: UIButton!
    
    @IBAction private func didClickLoudNotificationsToolTip(_ sender: Any) {
        loudNotificationsToolTip.isUserInteractionEnabled = false
        
        //snoozeLengthToolTip tool tip shown
        if toolTipViews[3] != nil {
            hideToolTip(targetTipView: toolTipViews[3]) {
                self.loudNotificationsToolTip.isUserInteractionEnabled = true
            }
        }
        //needs to show snoozeLengthToolTip
        else {
            showToolTip(sourceButton: loudNotificationsToolTip, message: "Notifications will ring\n despite your phone\nbeing silenced, locked,\nor on do not disturb.")
            //"Sends a follow up \nnotification if the first one\nis not responded to"
        }
    }
    //MARK: General Tool Tip
    
    func showToolTip(sourceButton: UIButton, message: String) {
        let tipView = ToolTipView(sourceView: sourceButton, message: message, toolTipPosition: .middle)
        sourceButton.superview?.addSubview(tipView)
        performToolTipShow(sourceButton: sourceButton, tipView)
        
        switch sourceButton {
            case followUpNotificationToolTip:
                toolTipViews[0] = tipView
            case snoozeLengthToolTip:
                toolTipViews[1] = tipView
            case pauseAllRemindersToolTip:
                toolTipViews[2] = tipView
            case loudNotificationsToolTip:
                toolTipViews[3] = tipView
            default:
                print("fall through showToolTip SettingsViewController")
        }
    }
    
    func hideToolTip(targetTipView: ToolTipView?, completion: (() -> Void)?) {
        
        if targetTipView != nil{
            UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: {
                targetTipView!.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }) { finished in
                targetTipView?.removeFromSuperview()
                
                for tipViewIndex in 0..<self.toolTipViews.count{
                    if self.toolTipViews[tipViewIndex] == targetTipView!{
                        self.toolTipViews[tipViewIndex] = nil
                    }
                }
                
                if completion != nil {
                    completion!()
                }
            }
        }
        else {
            for tipViewIndex in 0..<self.toolTipViews.count{
                var tipView = toolTipViews[tipViewIndex]
                guard tipView != nil else {
                    continue
                }
                UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: {
                    tipView!.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                }) { finished in
                    tipView?.removeFromSuperview()
                    tipView = nil
                }
            }
        }
        
        
    }
    
    ///If hideToolTip is exposed to objc and used in selector for tap gesture recognizer then for some reason
    @objc private func willHideToolTip(){
        hideToolTip(targetTipView: nil, completion: nil)
    }
    
    //MARK: - Reset
    @IBAction private func willReset(_ sender: Any) {
        self.willHideToolTip()
        
        let alertController = GeneralUIAlertController(
            title: "Are you sure you want to reset?",
            message: "This action will delete and reset all data to default, in the process restarting the app.",
            preferredStyle: .alert)
        
        let alertReset = UIAlertAction(
            title:"Reset",
            style: .destructive,
            handler:
                {
                    (alert: UIAlertAction!)  in
                    UserDefaults.standard.setValue(true, forKey: UserDefaultsKeys.shouldPerformCleanInstall.rawValue)
                    
                    let restartTimer = Timer(fireAt: Date(), interval: -1, target: self, selector: #selector(self.showRestartMessage), userInfo: nil, repeats: false)
                    
                    RunLoop.main.add(restartTimer, forMode: .common)
                })
        
        let alertCancel = UIAlertAction(title:"Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(alertReset)
        alertController.addAction(alertCancel)
        
        AlertPresenter.shared.enqueueAlertForPresentation(alertController)
        
    }
    
    @objc private func showRestartMessage(){
        let alertController = GeneralUIAlertController(
            title: "Restarting now....",
            message: nil,
            preferredStyle: .alert)
        
        AlertPresenter.shared.enqueueAlertForPresentation(alertController)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            exit(-1)
        }
    }
    
    //MARK: - Properties
    
    var delegate: SettingsViewControllerDelegate! = nil
    
    @IBOutlet private weak var scrollViewContainerForAll: UIView!
    
    private var toolTipViews: [ToolTipView?] = [nil, nil, nil, nil]
    
    //MARK: - Main
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //DARK MODE
        darkModeSegmentedControl.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.white], for: .normal)
        darkModeSegmentedControl.backgroundColor = .systemGray4
        
        //LOGS OVERVIEW MODE
        self.logsViewModeSegmentedControl.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 15), .foregroundColor: UIColor.white], for: .normal)
        self.logsViewModeSegmentedControl.backgroundColor = .systemGray4
        
        if AppearanceConstant.isCompactView == true {
            logsViewModeSegmentedControl.selectedSegmentIndex = 0
        }
        else {
            logsViewModeSegmentedControl.selectedSegmentIndex = 1
        }
        
        
        followUpDelayInterval.countDownDuration = NotificationConstant.followUpDelay
        snoozeInterval.countDownDuration = TimerConstant.defaultSnoozeLength
        
        //fixes issue with first time datepicker updates not triggering function
        DispatchQueue.main.asyncAfter(deadline: .now()){
            self.followUpDelayInterval.countDownDuration = NotificationConstant.followUpDelay
            self.snoozeInterval.countDownDuration = TimerConstant.defaultSnoozeLength
        }
        
        pauseToggleSwitch.isOn = TimingManager.isPaused
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(willHideToolTip))
        self.view.addGestureRecognizer(tap)
        
        self.buildNumber.text = "Version \(UIApplication.appVersion ?? "nil") - Build \(UIApplication.appBuild)"
        
        //setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utils.presenter = self
        
        //DARK MODE
        switch AppearanceConstant.darkModeStyle.rawValue {
        //system/unspecified
        case 0:
            darkModeSegmentedControl.selectedSegmentIndex = 2
        //light
        case 1:
            darkModeSegmentedControl.selectedSegmentIndex = 0
        //dark
        case 2:
            darkModeSegmentedControl.selectedSegmentIndex = 1
        default:
            darkModeSegmentedControl.selectedSegmentIndex = 2
        }
     
        
        
        //ELSE
        notificationToggleSwitch.isOn = NotificationConstant.isNotificationEnabled
        synchronizeNotificationsComponents(animated: false)
        synchronizeIsPaused()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        hideToolTip(targetTipView: nil, completion: nil)
    }
    
    private func setupConstraints(){
       
            /*
         func setupFollowUpLabelWidth(){
             var followUpReminderLabelWidth: CGFloat {
                 let neededConstraintSpace: CGFloat = 10.0 + 3.0 + 3.0 + 45.0
                 let otherButtonSpace: CGFloat = followUpToggleSwitch.frame.width + followUpNotificationToolTip.frame.width
                 let maximumWidth: CGFloat = view.frame.width - otherButtonSpace - neededConstraintSpace
                 
                 let neededLabelSize: CGSize = (followUpReminderLabel.text?.boundingFrom(font: followUpReminderLabel.font, height: followUpReminderLabel.frame.height))!
                 
                 let neededLabelWidth: CGFloat = neededLabelSize.width
                 
                 if neededLabelWidth > maximumWidth {
                     return maximumWidth
                 }
                 else {
                     return neededLabelWidth
                 }
             }
             
             let followUpLabelConstraint = NSLayoutConstraint(item: followUpReminderLabel!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: followUpReminderLabelWidth)
             followUpReminderLabel.addConstraint(followUpLabelConstraint)
             NSLayoutConstraint.activate([followUpLabelConstraint])
         }
             */
            
        
        func setupSnoozeLengthLabelWidth(){
            var snoozeLengthLabelWidth: CGFloat {
                let neededConstraintSpace: CGFloat = 10.0 + 3.0 + 3.0 + 45.0
                let otherButtonSpace: CGFloat = snoozeLengthLabel.frame.width + snoozeLengthToolTip.frame.width
                let maximumWidth: CGFloat = view.frame.width - otherButtonSpace - neededConstraintSpace
                
                let neededLabelSize: CGSize = (snoozeLengthLabel.text?.boundingFrom(font: snoozeLengthLabel.font, height: snoozeLengthLabel.frame.height))!
                
                let neededLabelWidth: CGFloat = neededLabelSize.width
                
                if neededLabelWidth > maximumWidth {
                    return maximumWidth
                }
                else {
                    return neededLabelWidth
                }
            }
            
            let snoozeLengthConstraint = NSLayoutConstraint(item: snoozeLengthLabel!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: snoozeLengthLabelWidth)
            snoozeLengthLabel.addConstraint(snoozeLengthConstraint)
            NSLayoutConstraint.activate([snoozeLengthConstraint])
        }
        
        func setupLoudNotificationLabelWidth(){
            var loudNotificationLabelWidth: CGFloat {
                let neededConstraintSpace: CGFloat = 10.0 + 3.0 + 3.0 + 45.0
                let otherButtonSpace: CGFloat = loudNotificationsLabel.frame.width + loudNotificationsToolTip.frame.width
                let maximumWidth: CGFloat = view.frame.width - otherButtonSpace - neededConstraintSpace
                
                let neededLabelSize: CGSize = (loudNotificationsLabel.text?.boundingFrom(font: loudNotificationsLabel.font, height: loudNotificationsLabel.frame.height))!
                
                let neededLabelWidth: CGFloat = neededLabelSize.width
                
                if neededLabelWidth > maximumWidth {
                    return maximumWidth
                }
                else {
                    return neededLabelWidth
                }
            }
            
            let loudNotificationLengthConstraint = NSLayoutConstraint(item: loudNotificationsLabel!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: loudNotificationLabelWidth)
            loudNotificationsLabel.addConstraint(loudNotificationLengthConstraint)
            NSLayoutConstraint.activate([loudNotificationLengthConstraint])
        }
        
        
        
        
        //setupFollowUpLabelWidth()
        setupSnoozeLengthLabelWidth()
        //setupLoudNotificationLabelWidth()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
}
