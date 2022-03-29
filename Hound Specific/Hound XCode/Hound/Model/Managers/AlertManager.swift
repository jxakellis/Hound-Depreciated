//
//  AlertManager.swift
//  AlertQueue-Example
//
//  Created by William Boles on 26/05/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//
//  Modified by Jonathan Xakellis on 2/5/21.
//

import UIKit

class AlertManager: NSObject {
    
    override init() {
        super.init()
    }
    
        // MARK: - Public Properties
    
    static var shared = AlertManager()
    
    /// Default sender used to present, this is necessary if an alert to be shown is called from a non UIViewController class as that is not in the view heirarchy and physically cannot present a view, so this is used instead.
    static var globalPresenter: UIViewController?
    
    // MARK: - Private Properties
    
    private var locked = false
    private var halted = false
    private var currentAlertPresented: GeneralUIAlertController?
    
    // MARK: - Queue
    
    private var alertQueue: [GeneralUIAlertController] = []
    
    /// Checks to see if the queue has any server related alerts inside of it.
    private var containsServerRelatedAlert: Bool {
        // check queue for server related
        for alert in alertQueue where alert.serverRelated == true {
            return true
        }
        // check current presentation
        if currentAlertPresented?.serverRelated == true {
            return true
        }
        else {
            return false
        }
    }
    
    private var queuePresent: Bool {
        return !(alertQueue.isEmpty)
    }
    
    private func enqueue(_ alertController: GeneralUIAlertController) {
         // if this is a server related alert and there is already a server related alert, we don't want to add a second one. no need to barrage the user with server failure messages.
            if alertController.serverRelated == true && containsServerRelatedAlert == true {
                return
            }
        
        alertQueue.append(alertController)
    }
    
    // MARK: - Alert Presentation
    
    /// Function used to present alertController. If the alert is related to a server query message, specifiy as so. This stops the user from being spammed with multiple server messages if there are multiple failure messages at once.
    static func willShowAlert(title: String, message: String?, serverRelated: Bool = false) {
        var trimmedMessage: String? = message
        
        if message?.trimmingCharacters(in: .whitespacesAndNewlines) == ""{
            trimmedMessage = nil
        }
        
        let alertController = GeneralUIAlertController(
            title: title,
            message: trimmedMessage,
            preferredStyle: .alert)
        alertController.serverRelated = serverRelated
        
        let alertAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        
        alertController.addAction(alertAction)
        
        enqueueAlertForPresentation(alertController)
        
    }
    
    // MARK: - Alert Queue Management
    
    static func enqueueAlertForPresentation(_ alertController: GeneralUIAlertController) {
        guard alertController.preferredStyle == .alert else {
            fatalError("use enqueueActionSheetForPresentation instead")
        }
        
        shared.enqueue(alertController)
        
        shared.showNextAlert()
    }
    
    static func enqueueActionSheetForPresentation(_ alertController: GeneralUIAlertController, sourceView: UIView, permittedArrowDirections: UIPopoverArrowDirection) {
        guard alertController.preferredStyle == .actionSheet else {
            fatalError("use enqueueAlertForPresentation instead")
        }
        
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        default:
            break
        }
        
        shared.enqueue(alertController)
        
        shared.showNextAlert()
    }
    
    private func showNextAlert() {
        guard halted == false else {
            return
        }
        
        func waitLoop() {
            if AlertManager.globalPresenter == nil || AlertManager.globalPresenter!.isBeingDismissed {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                    waitLoop()
                }
            }
            else {
                showNextAlert()
            }
            
        }
        
        if AlertManager.globalPresenter == nil {
            AppDelegate.generalLogger.notice("AlertManager.globalPresenter is nil, initiating waitLoop")
            waitLoop()
            
        }
        else if AlertManager.globalPresenter!.isBeingDismissed {
            AppDelegate.generalLogger.notice("AlertManager.globalPresenter is being dismissed, initiating waitLoop")
            waitLoop()
        }
        else {
            if queuePresent == true && locked == false {
                locked = true
                currentAlertPresented = alertQueue.first
                AlertManager.globalPresenter!.present(currentAlertPresented!, animated: true)
            }
        }
        
    }
    
    /// Invoke when the alert has finished being presented and a new alert is able to take its place
    func alertDidComplete() {
        locked = false
        currentAlertPresented = nil
        alertQueue.removeFirst()
        showNextAlert()
    }
    
    func refreshAlarms(dogManager: DogManager) {
        halted = true
        if currentAlertPresented == nil {
            for d in dogManager.dogs {
                for r in d.dogReminders.reminders where r.isPresentationHandled == true {
                    AlarmManager.willShowAlarm(dogName: d.dogName, dogId: d.dogId, reminder: r)
                }
            }
        }
        halted = false
        showNextAlert()
    }
}