//
//  RequestUtils.swift
//  Hound
//
//  Created by Jonathan Xakellis on 2/25/22.
//  Copyright © 2022 Jonathan Xakellis. All rights reserved.
//

import Foundation

enum RequestUtils {
    
    /**
     Invoke function when the user is terminating the app. Sends a query to the server to send an APN to the user, warning against terminating the app
     */
    static func createTerminationNotification() {
        InternalRequestUtils.genericPostRequest(invokeErrorManager: false, forURL: UserRequest.baseURLWithUserId.appendingPathComponent("/alert/terminate"), forBody: [:]) { _, _ in
        }
    }
    
    enum RequestIndicatorType {
        case apple
        case hound
    }
    
    /// Presents a custom made contactingHoundServerAlertController on the global presentor that blocks everything until endRequestIndictator is called
    static func beginRequestIndictator(forRequestIndicatorType requestIndicatorType: RequestIndicatorType = .hound) {
        switch requestIndicatorType {
        case .hound:
            AlertManager.shared.contactingServerAlertController.title = "Contacting Hound's Server..."
        case .apple:
            AlertManager.shared.contactingServerAlertController.title = "Contacting Apple's Server..."
        }
        AlertManager.enqueueAlertForPresentation(AlertManager.shared.contactingServerAlertController)
    }
    
    /// Dismisses the custom made contactingHoundServerAlertController. Allow the app to resume normal execution once the completion handler is called (as that indicates the contactingHoundServerAlertController was dismissed and new things can be presented/segued to).
    static func endRequestIndictator(completionHandler: @escaping () -> Void) {
        AlertManager.shared.contactingServerAlertController.dismiss(animated: false) {
            completionHandler()
        }
    }
}