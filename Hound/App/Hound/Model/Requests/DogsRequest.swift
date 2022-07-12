//
//  DogsRequest.swift
//  Hound
//
//  Created by Jonathan Xakellis on 2/28/22.
//  Copyright © 2022 Jonathan Xakellis. All rights reserved.
//

import Foundation

enum DogsRequest: RequestProtocol {

    static var baseURLWithoutParams: URL { return FamilyRequest.baseURLWithFamilyId.appendingPathComponent("/dogs") }
    
    // MARK: - Private Functions
    
    /**
     completionHandler returns response data: dictionary of the body and the ResponseStatus
     */
    private static func internalGet(invokeErrorManager: Bool, forDogId dogId: Int?, completionHandler: @escaping ([String: Any]?, ResponseStatus) -> Void) {
        
        InternalRequestUtils.warnForPlaceholderId(dogId: dogId)
        
        let URLWithParams: URL
        var urlComponents: URLComponents!
        // special case where we append the query parameter of all. Its value doesn't matter but it just tells the server that we want the logs and reminders of the dog too.
        if dogId != nil {
            urlComponents = URLComponents(url: baseURLWithoutParams.appendingPathComponent("/\(dogId!)"), resolvingAgainstBaseURL: false)!
        }
        else {
            urlComponents = URLComponents(url: baseURLWithoutParams.appendingPathComponent(""), resolvingAgainstBaseURL: false)!
        }
        
        // if we are querying about a dog, we always want its reminders and logs
        urlComponents.queryItems = [
            URLQueryItem(name: "reminders", value: "true"),
            URLQueryItem(name: "logs", value: "true"),
            URLQueryItem(name: "lastDogManagerSynchronization", value: LocalConfiguration.lastDogManagerSynchronization.ISO8601FormatWithFractionalSeconds())
        ]
        
        URLWithParams = urlComponents.url!
        
        // make get request
        InternalRequestUtils.genericGetRequest(invokeErrorManager: invokeErrorManager, forURL: URLWithParams) { responseBody, responseStatus in
            completionHandler(responseBody, responseStatus)
        }
        
    }
    
    /**
     completionHandler returns response data: dogId for the created dog and the ResponseStatus
     */
    private static func internalCreate(invokeErrorManager: Bool, forDog dog: Dog, completionHandler: @escaping ([String: Any]?, ResponseStatus) -> Void) {
        InternalRequestUtils.warnForPlaceholderId()
        let body = dog.createBody()
        
        // make put request, assume body valid as constructed with method
        InternalRequestUtils.genericPostRequest(invokeErrorManager: invokeErrorManager, forURL: baseURLWithoutParams, forBody: body) { responseBody, responseStatus in
            completionHandler(responseBody, responseStatus)
        }
    }
    
    /**
     completionHandler returns response data: dictionary of the body and the ResponseStatus
     */
    private static func internalUpdate(invokeErrorManager: Bool, forDog dog: Dog, completionHandler: @escaping ([String: Any]?, ResponseStatus) -> Void) {
        
        InternalRequestUtils.warnForPlaceholderId(dogId: dog.dogId)
        let URLWithParams: URL = baseURLWithoutParams.appendingPathComponent("/\(dog.dogId)")
        
        let body = dog.createBody()
        
        // make put request, assume body valid as constructed with method
        InternalRequestUtils.genericPutRequest(invokeErrorManager: invokeErrorManager, forURL: URLWithParams, forBody: body) { responseBody, responseStatus in
            completionHandler(responseBody, responseStatus)
        }
        
    }
    
    /**
     completionHandler returns response data: dictionary of the body and the ResponseStatus
     */
    private static func internalDelete(invokeErrorManager: Bool, forDogId dogId: Int, completionHandler: @escaping ([String: Any]?, ResponseStatus) -> Void) {
        
        InternalRequestUtils.warnForPlaceholderId(dogId: dogId)
        let URLWithParams: URL = baseURLWithoutParams.appendingPathComponent("/\(dogId)")
        
        // make delete request
        InternalRequestUtils.genericDeleteRequest(invokeErrorManager: invokeErrorManager, forURL: URLWithParams) { responseBody, responseStatus in
            completionHandler(responseBody, responseStatus)
        }
        
    }
    
}

extension DogsRequest {
    
    // MARK: - Public Functions
    
    /**
     completionHandler returns a dog. If the query returned a 200 status and is successful, then the dog is returned (the client-side dog is combined with the server-side updated dog). Otherwise, if there was a problem, nil is returned and ErrorManager is automatically invoked.
     */
    static func get(invokeErrorManager: Bool, dog currentDog: Dog, completionHandler: @escaping (Dog?, ResponseStatus) -> Void) {
        
        DogsRequest.internalGet(invokeErrorManager: invokeErrorManager, forDogId: currentDog.dogId) { responseBody, responseStatus in
            switch responseStatus {
            case .successResponse:
                // Array of log JSON [{dog1:'foo'},{dog2:'bar'}]
                if let newDogBody = responseBody?[ServerDefaultKeys.result.rawValue] as? [[String: Any]] {
                    
                    guard newDogBody.count != 0 else {
                        // the dog wasn't updated since last opened
                        completionHandler(currentDog, responseStatus)
                        return
                    }
                    
                    // the dog was updated since last opened
                    let newDog = Dog(fromBody: newDogBody[0])
                    
                    guard newDog.dogIsDeleted == false else {
                        completionHandler(nil, responseStatus)
                        return
                    }
                    
                    newDog.combine(withOldDog: currentDog)
                    // If we have an image stored locally for a dog, then we apply the icon.
                    // If the dog has no icon (because someone else in the family made it and the user hasn't selected their own icon OR because the user made it and never added an icon) then the dog just gets the defaultDogIcon
                    newDog.dogIcon = LocalDogIcon.getIcon(forDogId: newDog.dogId) ?? DogConstant.defaultDogIcon
                    
                    // delete any newReminder with the marker that they should be deleted
                    for newReminder in newDog.dogReminders.reminders where newReminder.reminderIsDeleted == true {
                        try? newDog.dogReminders.removeReminder(forReminderId: newReminder.reminderId)
                    }
                    // delere any newLog with the marker that they should be deleted
                    for newLog in newDog.dogLogs.logs where newLog.logIsDeleted == true {
                        try? newDog.dogLogs.removeLog(forLogId: newLog.logId)
                    }
                    
                    completionHandler(newDog, responseStatus)
                }
                else {
                    completionHandler(nil, responseStatus)
                }
            case .failureResponse:
                completionHandler(nil, responseStatus)
            case .noResponse:
                completionHandler(nil, responseStatus)
            }
        }
    }
    
    /**
     First refreshes the FamilyConfiguration of the user to make sure everything is synced up (e.g. isPaused). completionHandler returns a dogManager. If the query returned a 200 status and is successful, then the dogManager is returned (the client-side dogManager is combined with the server-side updated dogManager). Otherwise, if there was a problem, nil is returned and ErrorManager is automatically invoked.
     */
    static func get(invokeErrorManager: Bool, dogManager currentDogManager: DogManager, completionHandler: @escaping (DogManager?, ResponseStatus) -> Void) {
        
        // We want to sync the isPaused status before getting the newDogManager. Otherwise, reminder could be up to date but alarms could be going off locally since the local app doesn't realized that the app was paused (the opposite with an unpause could also be possible
        FamilyRequest.get(invokeErrorManager: invokeErrorManager) { requestWasSuccessful, responseStatus in
            guard requestWasSuccessful == true else {
                return completionHandler(nil, responseStatus)
            }
            
            // we want this Date() to be slightly in the past. If we set  LocalConfiguration.lastDogManagerSynchronization = Date() after the request is successful then any changes that might have occured DURING our query (e.g. we are querying and at the exact same moment a family member creates a log) will not be saved. Therefore, this is more redundant and makes sure nothing is missed
            let lastDogManagerSynchronization = Date()
            
            // Now can get the dogManager
            DogsRequest.internalGet(invokeErrorManager: invokeErrorManager, forDogId: nil) { responseBody, responseStatus in
                switch responseStatus {
                case .successResponse:
                    if let newDogManagerBody = responseBody?[ServerDefaultKeys.result.rawValue] as? [[String: Any]], let newDogManager = DogManager(fromBody: newDogManagerBody) {
                        // successful sync, so we can update value
                        LocalConfiguration.lastDogManagerSynchronization = lastDogManagerSynchronization
                        
                        newDogManager.combine(withOldDogManager: currentDogManager)
                        
                        // Check to see if any dogs have the marker that they should be deleted
                        // We do it this way as if we immediatly deleted the dog/reminder/log when converting the JSON to object, then the dog/reminder/log from the oldDogManager would still be present. This way allows us to create a dog/reminder/log that overwrites the oldDogManager's dog/reminder/log, but leaves this boolean in place to tell us whether it belongs or not.
                        for newDog in newDogManager.dogs {
                            // find any newDogs with the marker that they should be deleted, if they need to be, then no point to iterating through their logs/reminders
                            if newDog.dogIsDeleted == true {
                                try? newDogManager.removeDog(forDogId: newDog.dogId)
                            }
                            // dog shouldn't be deleted, so verify its reminders/logs
                            else {
                                // delete any newReminder with the marker that they should be deleted
                                for newReminder in newDog.dogReminders.reminders where newReminder.reminderIsDeleted == true {
                                    try? newDog.dogReminders.removeReminder(forReminderId: newReminder.reminderId)
                                }
                                // delere any newLog with the marker that they should be deleted
                                for newLog in newDog.dogLogs.logs where newLog.logIsDeleted == true {
                                    try? newDog.dogLogs.removeLog(forLogId: newLog.logId)
                                }
                            }
                        }
                        
                        LocalDogIcon.checkForExtraIcons(forDogs: newDogManager.dogs)
                        
                        completionHandler(newDogManager, responseStatus)
                    }
                    else {
                        completionHandler(nil, responseStatus)
                    }
                case .failureResponse:
                    completionHandler(nil, responseStatus)
                case .noResponse:
                    completionHandler(nil, responseStatus)
                }
            }
        }
        
    }
    
    /**
     completionHandler returns a possible dogId and the ResponseStatus.
     If invokeErrorManager is true, then will send an error to ErrorManager that alerts the user.
     */
    static func create(invokeErrorManager: Bool, forDog dog: Dog, completionHandler: @escaping (Int?, ResponseStatus) -> Void) {
        DogsRequest.internalCreate(invokeErrorManager: invokeErrorManager, forDog: dog) { responseBody, responseStatus in
            switch responseStatus {
            case .successResponse:
                if let dogId = responseBody?[ServerDefaultKeys.result.rawValue] as? Int {
                    // Successfully saved to server, so save dogIcon locally
                    // add a localDogIcon that has the same dogId and dogIcon as the newly created dog
                    LocalDogIcon.addIcon(forDogId: dogId, forDogIcon: dog.dogIcon)
                    completionHandler(dogId, responseStatus)
                }
                else {
                    completionHandler(nil, responseStatus)
                }
            case .failureResponse:
                completionHandler(nil, responseStatus)
            case .noResponse:
                completionHandler(nil, responseStatus)
            }
            
        }
    }
    
    /**
     completionHandler returns a Bool and the ResponseStatus, indicating whether or not the request was successful
     If invokeErrorManager is true, then will send an error to ErrorManager that alerts the user.
     */
    static func update(invokeErrorManager: Bool, forDog dog: Dog, completionHandler: @escaping (Bool, ResponseStatus) -> Void) {
        DogsRequest.internalUpdate(invokeErrorManager: invokeErrorManager, forDog: dog) { _, responseStatus in
            switch responseStatus {
            case .successResponse:
                // Successfully saved to server, so update dogIcon locally
                // check to see if a localDogIcon exists for the dog
                LocalDogIcon.addIcon(forDogId: dog.dogId, forDogIcon: dog.dogIcon)
                completionHandler(true, responseStatus)
            case .failureResponse:
                completionHandler(false, responseStatus)
            case .noResponse:
                completionHandler(false, responseStatus)
            }
        }
    }
    
    /**
     completionHandler returns a Bool and the ResponseStatus, indicating whether or not the request was successful.
     If invokeErrorManager is true, then will send an error to ErrorManager that alerts the user.
     */
    static func delete(invokeErrorManager: Bool, forDogId dogId: Int, completionHandler: @escaping (Bool, ResponseStatus) -> Void) {
        DogsRequest.internalDelete(invokeErrorManager: invokeErrorManager, forDogId: dogId) { _, responseStatus in
            switch responseStatus {
            case .successResponse:
                // Successfully saved to server, so remove the stored dogIcons that have the same dogId as the removed dog
                LocalDogIcon.removeIcon(forDogId: dogId)
                completionHandler(true, responseStatus)
            case .failureResponse:
                completionHandler(false, responseStatus)
            case .noResponse:
                completionHandler(false, responseStatus)
            }
        }
    }
}