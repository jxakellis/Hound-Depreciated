//
//  Timing.swift
//  Who Let The Dogs Out
//
//  Created by Jonathan Xakellis on 11/20/20.
//  Copyright © 2020 Jonathan Xakellis. All rights reserved.
//

import UIKit

protocol TimingManagerDelegate {
    func didUpdateDogManager(newDogManager: DogManager, sender: AnyObject?)
}

class TimingManager: TimingProtocol {
    
    //MARK: MAIN
    
    static var delegate: TimingManagerDelegate! = nil
    
    ///saves the state when all alarms are paused: (Last Pause, Is Currently Paused, Last Unpause)
    static var pauseState: (Date?, Bool, Date?) = (nil, false, nil)
    
    ///Corrolates to dogManager: "
    ///Dictionary<dogName: String, Dictionary<requirementName: String, associatedTimer: Timer>>"
    
    /// IMPORTANT NOTE: DO NOT COPY, WILL MAKE MULTIPLE TIMERS WHICH WILL FIRE SIMULTANIOUSLY
    static var timerDictionary: Dictionary<String,Dictionary<String,Timer>> = Dictionary<String,Dictionary<String,Timer>>()
    
    //MARK: TimingProtocol Implementation
    
    
    static func willInitalize(dogManager: DogManager, didUnpause: Bool = false){
        ///Takes a DogManager and potentially a Bool of if all alarms were unpaused, goes through the dog manager and finds all enabled requirements under all enabled dogs and sets a timer to fire.
        
        //Makes sure pauseAllAlarms is false, don't want to instantiate alarms when they should be paused
        guard self.pauseState.1 == false else {
            return
        }
        
        //goes through all dogs
        for d in 0..<dogManager.dogs.count{
            //makes sure current dog is enabled, as if it isn't then all of its alarms arent either
            guard dogManager.dogs[d].getEnable() == true else {
                continue
            }
            
            //goes through all requirements in a dog
            for r in 0..<dogManager.dogs[d].dogRequirments.requirements.count{
                
                let requirement = dogManager.dogs[d].dogRequirments.requirements[r]
                
                //makes sure a requirement is enabled
                guard requirement.getEnable() == true
                else{
                    continue
                }
                
                var executionDate: Date! = nil
                
                //If transitioning from paused to unpaused, calculates execution date differently, this is because the alarm elasped an amount of time before it was paused, so it only has its interval minus the time elapsed left to go.
                if didUnpause == true {
                    
                    var intervalLeft: TimeInterval! = nil
                    
                    if requirement.isSnoozed == true{
                        intervalLeft = TimerConstant.defaultSnooze - requirement.intervalElapsed
                    }
                    else{
                        intervalLeft = requirement.executionInterval - requirement.intervalElapsed
                    }
                    
                    executionDate = Date.executionDate(lastExecution: Date(), interval: intervalLeft)
                    
                    //debug info
                    //print("originalDate: \(pauseState.2)  pausedDate: \(pauseState.0!) currentDate: \(Date()) intervalElapsed: \(intervalElapsed.description) intervalLeft: \(intervalLeft.description) executionDate: \(executionDate.description)")
                }
                
                //If not transitioning from unpaused, calculates execution date traditionally
                else if didUnpause == false{
                    if requirement.isSnoozed == true{
                        executionDate = Date.executionDate(lastExecution: requirement.lastExecution, interval: TimerConstant.defaultSnooze)
                    }
                    else{
                        executionDate = Date.executionDate(lastExecution: dogManager.dogs[d].dogRequirments.requirements[r].lastExecution, interval: dogManager.dogs[d].dogRequirments.requirements[r].executionInterval)
                    }
                }
                
                if Date().distance(to: executionDate) < 0 {
                    continue
                }
                
                let timer = Timer(fireAt: executionDate,
                                  interval: -1,
                                  target: self,
                                  selector: #selector(self.didExecuteTimer(sender:)),
                                  userInfo: try! ["dogName": dogManager.dogs[d].dogSpecifications.getDogSpecification(key: "name"), "requirement": dogManager.dogs[d].dogRequirments.requirements[r], "dogManager": dogManager],
                                  repeats: false)
                
                RunLoop.main.add(timer, forMode: .common)
                
                //Updates timerDictionary to reflect new alarm added, this is so a reference to the created timer can be referenced later and invalidated if needed.
                var nestedtimerDictionary: Dictionary<String, Timer> = try! timerDictionary[dogManager.dogs[d].dogSpecifications.getDogSpecification(key: "name")] ?? Dictionary<String, Timer>()
                
                nestedtimerDictionary[requirement.name] = timer
                
                try! timerDictionary[dogManager.dogs[d].dogSpecifications.getDogSpecification(key: "name")] = nestedtimerDictionary
            }
        }
    }
    
    
    static func willReinitalize(dogManager: DogManager) {
        ///Reinitalizes all alarms when a new dogManager is sent
        self.invalidateAll()
        self.willInitalize(dogManager: dogManager)
    }
    
    ///Not implented currently
    static func willReinitalize(dogName: String, requirementName: String) throws {
        
    }
    
   
    @objc private static func didExecuteTimer(sender: Timer){
        ///Used as a selector when constructing timer in willInitalize, when called at an unknown point in time by the timer it presents an alert and updates information about the requirement
        guard let parsedDictionary = sender.userInfo as? [String: Any]
        else{
            ErrorProcessor.handleError(error: TimingManagerError.parseSenderInfoFailed, sender: self)
            return
        }
        
        let dogManager: DogManager = parsedDictionary["dogManager"]! as! DogManager
        let dogName: String = parsedDictionary["dogName"]! as! String
        let requirement: Requirement = parsedDictionary["requirement"]! as! Requirement

        let sudoDogManager = dogManager
        var sudoRequirement: Requirement = try! sudoDogManager.findDog(dogName: dogName).dogRequirments.findRequirement(requirementName: requirement.name)
        sudoRequirement.changeIntervalElapsed(newIntervalElapsed: TimeInterval(0))
        sudoRequirement.isSnoozed = false
        
        delegate.didUpdateDogManager(newDogManager: sudoDogManager, sender: self)
        
        let title = "\(requirement.name) - \(dogName)"
        let message = " \(requirement.description)"
        let reinitilizationInfo: (String, Requirement, DogManager) = (dogName, requirement, sudoDogManager)
        
        TimingManager.willShowTimer(title: title, message: message, reinitilizationInfo: reinitilizationInfo)
    }
    
    
    private static func invalidateAll() {
        ///Invalidates all timers
        for dogKey in timerDictionary.keys{
            for requirementKey in timerDictionary[dogKey]!.keys {
                timerDictionary[dogKey]![requirementKey]!.invalidate()
            }
        }
    }
    
    
    private static func invalidate(dogName: String, requirementName: String) throws {
        ///Invalidates a specific timer
        if timerDictionary[dogName] == nil{
            throw TimingManagerError.invalidateFailed
        }
        if timerDictionary[dogName]![requirementName] == nil {
            throw TimingManagerError.invalidateFailed
        }
        timerDictionary[dogName]![requirementName]!.invalidate()
    }
    
    
    static func willTogglePause(dogManager: DogManager, newPauseStatus: Bool) {
        ///Toggles pause status of timers, called when pauseAllAlarms in settings is switched to a new state
        if newPauseStatus == true {
            self.pauseState.0 = Date()
            self.pauseState.1 = true
            
            willPause(dogManager: dogManager)
            
            invalidateAll()
            
        }
        else {
            self.pauseState.2 = Date()
            self.pauseState.1 = false
            willInitalize(dogManager: dogManager, didUnpause: true)
        }
    }
    
    ///Updates dogManager to reflect the changes in intervalElapsed
    private static func willPause(dogManager: DogManager){
        let sudoDogManager = dogManager
        for dogKey in timerDictionary.keys{
            for requirementKey in timerDictionary[dogKey]!.keys {
                
                var sudoRequirement = try! sudoDogManager.findDog(dogName: dogKey).dogRequirments.findRequirement(requirementName: requirementKey)
                
                if sudoRequirement.intervalElapsed <= 0.01 {
                    sudoRequirement.changeIntervalElapsed(newIntervalElapsed: sudoRequirement.lastExecution.distance(to: pauseState.0!))
                }
                else{
                    sudoRequirement.changeIntervalElapsed(newIntervalElapsed: (sudoRequirement.intervalElapsed + pauseState.2!.distance(to: (pauseState.0!))))
                }
                
            }
        }
        
        delegate.didUpdateDogManager(newDogManager: sudoDogManager, sender: self)
    }
    
    private static func willShowTimer(sender: AnyObject = Utils.presenter, title: String, message: String, reinitilizationInfo: (String, Requirement, DogManager)){
        
        let dogManager = reinitilizationInfo.2
        
        let requirement = reinitilizationInfo.1
        
        let alertController = CustomAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        
        let alertActionDone = UIAlertAction(
            title:"Did it!",
            style: .cancel,
            handler:
                {
                    (alert: UIAlertAction!)  in
                    TimingManager.willResetAlarm(requirement: requirement, dogManager: dogManager)
                })
        let alertActionSnooze = UIAlertAction(
            title:"Snooze",
            style: .default,
            handler:
                {
                    (alert: UIAlertAction!)  in
                    TimingManager.willSnoozeAlarm(requirement: requirement, dogManager: dogManager)
                })
        let alertActionDisable = UIAlertAction(
            title:"Disable",
            style: .destructive,
            handler:
                {
                    (alert: UIAlertAction!)  in
                    TimingManager.willDisableAlarm(requirement: requirement, dogManager: dogManager)
                })
        alertController.addAction(alertActionDone)
        alertController.addAction(alertActionSnooze)
        alertController.addAction(alertActionDisable)
        
        AlertPresenter.shared.enqueueAlertForPresentation(alertController)
        
    }
    
    static func willDisableAlarm(requirement targetRequirement: Requirement, dogManager: DogManager){
        var requirement = targetRequirement
        requirement.setEnable(newEnableStatus: false)
        requirement.changeLastExecution(newLastExecution: Date())
        delegate.didUpdateDogManager(newDogManager: dogManager, sender: self)
    }
    
    static func willSnoozeAlarm(requirement targetRequirement: Requirement, dogManager: DogManager){
        var requirement = targetRequirement
        requirement.isSnoozed = true
        requirement.changeLastExecution(newLastExecution: Date())
        delegate.didUpdateDogManager(newDogManager: dogManager, sender: self)
        TimingManager.willReinitalize(dogManager: dogManager)
    }
    
    static func willResetAlarm(requirement targetRequirement: Requirement, dogManager: DogManager){
        var requirement = targetRequirement
        requirement.changeLastExecution(newLastExecution: Date())
        delegate.didUpdateDogManager(newDogManager: dogManager, sender: self)
        TimingManager.willReinitalize(dogManager: dogManager)
    }
}
