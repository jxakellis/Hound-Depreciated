//
//  ServerSyncViewController.swift
//  Hound
//
//  Created by Jonathan Xakellis on 3/3/22.
//  Copyright © 2022 Jonathan Xakellis. All rights reserved.
//

import UIKit

class ServerSyncViewController: UIViewController {

    /*
     
     Sync Flow:
     
     START
     - Fetch userConfiguration (with userId)
         - userId valid and authenticated
            - Fetch familyId (with userId)
                - familyId valid and authenticated
                    - fetch dogs, logs, reminders, and shared configuration
                - familyId invalid and/or not authenticated
                    - create family
                        - return to start
                    - join family
                        - return to start
         - userId invalid and/or not authenticated
            - create user
                - return to start
            - login user
                - return to start
     
     */

    // MARK: - IB

    @IBOutlet private weak var statusLabel: UILabel!

    // MARK: - Main
    override func viewDidLoad() {
        super.viewDidLoad()

        updateStatusLabel()
        let retryAlertAction = UIAlertAction(title: "Retry Connection", style: .default) { _ in
            self.retrySynchronization()
        }
        failureResponseAlertController.addAction(retryAlertAction)
        noResponseAlertController.addAction(retryAlertAction)
        noDogManagerAlertController.addAction(retryAlertAction)
        
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        // Called before the view is added to the windows’ view hierarchy
        super.viewWillAppear(animated)
        // Make this view the presenter if the app has to present any alert.
        AlertManager.globalPresenter = self

        // make sure the view has the correct interfaceStyle
        UIApplication.keyWindow?.overrideUserInterfaceStyle = UserConfiguration.interfaceStyle
        // placeholder userId
        if UserInformation.userId == nil || UserInformation.userId! < 0 {
            // we have the user sign into their apple id, then attempt to first create an account then get an account (if the creates fails) then throw an error message (if the get fails too).
            // if all succeeds, then the user information and user configuration is loaded
            Utils.performSegueOnceInWindowHierarchy(segueIdentifier: "serverLoginViewController", viewController: self)
        }
        // has userId, possibly has familyId, will check inside getUser
        else {
            getUser()
        }
    }

    // MARK: - Properties
    /// Called to prompt the user to retry a server connection
    private var failureResponseAlertController = GeneralUIAlertController(title: "Uh oh! There was a problem.", message: GeneralResponseError.failureGetResponse.rawValue, preferredStyle: .alert)
    private var noResponseAlertController = GeneralUIAlertController(title: "Uh oh! There was a problem.", message: GeneralResponseError.noGetResponse.rawValue, preferredStyle: .alert)
    private var noDogManagerAlertController = GeneralUIAlertController(title: "Uh oh! There was a problem.", message: "We experienced an issue while retrieving your data Hound's server. Our first request to retrieve your app settings succeeded, but we were unable to retrieve your dogs. Please verify that you are connected to the internet and retry. If the issue persists, please reinstall Hound.", preferredStyle: .alert)

    /// DogManager that all of the retrieved information will be added too.
    private var dogManager = DogManager()

    // Only one call is made to the the user and one call to get all the dogs.
    private var serverContacted = false
    private var getUserFinished = false
    private var getFamilyFinished = false
    private var getDogsFinished = false
    
    // MARK: - Functions
    
    /// We failed to retrieve a familyId for the user so that means they have no family. Segue to page to make them create/join one.
    private func getFamily() {
        Utils.performSegueOnceInWindowHierarchy(segueIdentifier: "serverFamilyViewController", viewController: self)
    }

    // MARK: - Primary Sync
    
    /// Retrieve the user
    private func getUser() {
        // make sure that the labels are up to date. we want to reset all to false when we begin query.
        serverContacted = false
        getUserFinished = false
        getFamilyFinished = false
        getDogsFinished = false
        updateStatusLabel()
        
        UserRequest.get { responseBody, responseStatus in
            DispatchQueue.main.async {
                switch responseStatus {
                case .successResponse:
                    if responseBody != nil {
                        self.serverContacted = true
                        self.updateStatusLabel()
                        
                        // verify that at least one user was returned. Shouldn't be possible to have no users but always good to check
                        if let result = responseBody![ServerDefaultKeys.result.rawValue] as? [String: Any], result.isEmpty == false {
                            // set all local configuration equal to whats in the server
                            UserInformation.setup(fromBody: result)
                            UserConfiguration.setup(fromBody: result)
                            
                            // verify that a userId was successfully retrieved from the server
                            if result[ServerDefaultKeys.userId.rawValue] is Int {
                                self.getUserFinished = true
                                // if the user has create a hound account or signed into an existing one, we try to load the familyId returned to them. if that is nil, then we open this menu to have them create or join once since they aren't currently one.
                                
                                // user has family
                                if result[ServerDefaultKeys.familyId.rawValue] is Int {
                                    self.getFamilyFinished = true
                                    self.getDogs()
                                }
                                // no family for user
                                else {
                                    self.getFamily()
                                }
                                
                            }
                            
                            self.checkSynchronizationStatus()
                        }
                        else {
                            // TO DO if the user is failed to log in, parse the error messages and alert them to the reason as to why, alternatively, just send them to the login page again. E.g. the user had an account and so we had the userId stored locally, but the account got deleted so it now is a failure response when we try to login. 
                            AlertManager.enqueueAlertForPresentation(self.failureResponseAlertController)
                        }
                    }
                    else {
                        // TO DO if the user is failed to log in, parse the error messages and alert them to the reason as to why, alternatively, just send them to the login page again. E.g. the user had an account and so we had the userId stored locally, but the account got deleted so it now is a failure response when we try to login.
                        AlertManager.enqueueAlertForPresentation(self.failureResponseAlertController)
                    }
                case .failureResponse:
                    // TO DO if the user is failed to log in, parse the error messages and alert them to the reason as to why, alternatively, just send them to the login page again. E.g. the user had an account and so we had the userId stored locally, but the account got deleted so it now is a failure response when we try to login.
                    AlertManager.enqueueAlertForPresentation(self.failureResponseAlertController)
                case .noResponse:
                    AlertManager.enqueueAlertForPresentation(self.noResponseAlertController)
                }
            }
            
        }
    }

    /// Retrieve any dogs the user may have
    private func getDogs() {
        RequestUtils.getDogManager { dogManager in
            if dogManager != nil {
                self.dogManager = dogManager!
                self.getDogsFinished = true
                self.checkSynchronizationStatus()
            }
            else {
                AlertManager.enqueueAlertForPresentation(self.noDogManagerAlertController)
            }
        }
    }

    /// If all the request has successfully completed, persist the new dogManager to memory and continue into the hound app.
    private func checkSynchronizationStatus() {

        updateStatusLabel()

        guard serverContacted && getUserFinished && getFamilyFinished && getDogsFinished else {
            return
        }
        
            // figure out where to go next, if the user is new and has no dogs (aka probably no family yet either) then we help them make their first dog
            
            // hasn't shown configuration to create dog
            if LocalConfiguration.hasLoadedIntroductionViewControllerBefore == false {
                // never created a dog before, new family
                if self.dogManager.hasCreatedDog == false {
                    Utils.performSegueOnceInWindowHierarchy(segueIdentifier: "introductionViewController", viewController: self)
                }
                // dogs already created
                else {
                    // TO DO create intro page for additional family member, where they still get introduced but don't create a dog
                    
                    Utils.performSegueOnceInWindowHierarchy(segueIdentifier: "mainTabBarViewController", viewController: self)
                    LocalConfiguration.hasLoadedIntroductionViewControllerBefore = false
                }
                
            }
            // has shown configuration before
            else {
                Utils.performSegueOnceInWindowHierarchy(segueIdentifier: "mainTabBarViewController", viewController: self)
            }
            
    }
    
    /// Update status label from a synchronous code. This will produce a 'purple' error if used from a callback or other sync function
    private func updateStatusLabel() {
        let finishedContact = "      Contacting Server ✅\n"
        let inProgressContact = "      Contacting Server ❌\n"
        if self.serverContacted == true {
            self.statusLabel.text! = finishedContact
        }
        else {
            self.statusLabel.text! = inProgressContact
        }
        let finishedUser = "      Fetching User ✅\n"
        let inProgressUser = "      Fetching User ❌\n"
        if self.getUserFinished == true {
            self.statusLabel.text!.append(finishedUser)
        }
        else {
            self.statusLabel.text!.append(inProgressUser)
        }
        let finishedUserConfiguration = "      Fetching User Configuration ✅\n"
        let inProgressUserConfiguration = "      Fetching User Configuration ❌\n"
        if self.getUserFinished == true {
            self.statusLabel.text!.append(finishedUserConfiguration)
        }
        else {
            self.statusLabel.text!.append(inProgressUserConfiguration)
        }
        
        let finishedFamily = "      Fetching Family ✅\n"
        let inProgressFamily = "      Fetching Family ❌\n"
        if self.getFamilyFinished == true {
            self.statusLabel.text!.append(finishedFamily)
        }
        else {
            self.statusLabel.text!.append(inProgressFamily)
        }

        let finishedDogs = "      Fetching Dogs ✅"
        let inProgressDogs = "      Fetching Dogs ❌"
        if self.getDogsFinished == true {
            self.statusLabel.text!.append(finishedDogs)
        }
        else {
            self.statusLabel.text!.append(inProgressDogs)
        }
    }
    /// Server sync failed and cannot continue into the Hound app. This function attempts to retry the whole process from the very beginning.
    private func retrySynchronization() {
        serverContacted = false
        getUserFinished = false
        getFamilyFinished = false
        getDogsFinished = false
        updateStatusLabel()
        getUser()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "mainTabBarViewController"{
            let mainTabBarViewController: MainTabBarViewController = segue.destination as! MainTabBarViewController
            mainTabBarViewController.setDogManager(sender: Sender(origin: self, localized: self), newDogManager: dogManager)
        }
    }

}
