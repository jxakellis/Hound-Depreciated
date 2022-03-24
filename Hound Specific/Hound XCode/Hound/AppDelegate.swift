//
//  AppDelegate.swift
//  Hound
//
//  Created by Jonathan Xakellis on 11/4/20.
//  Copyright © 2020 Jonathan Xakellis. All rights reserved.
//

import UIKit
import UserNotifications
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static var generalLogger = Logger(subsystem: "com.example.Pupotty", category: "General")
    static var lifeCycleLogger = Logger(subsystem: "com.example.Pupotty", category: "Life Cycle")
    static var APIRequestLogger = Logger(subsystem: "com.example.Pupotty", category: "API Request")
    static var APIResponseLogger = Logger(subsystem: "com.example.Pupotty", category: "API Response")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        AppDelegate.lifeCycleLogger.notice("Application Did Finish Launching with Options")
        AppDelegate.generalLogger.notice("\n-----Device Info-----\n Model: \(UIDevice.current.model) \n Name: \(UIDevice.current.name) \n System Name: \(UIDevice.current.systemName) \n System Version: \(UIDevice.current.systemVersion)")

        UIApplication.previousAppBuild = UserDefaults.standard.object(forKey: UserDefaultsKeys.appBuild.rawValue) as? Int

        UserDefaults.standard.setValue(UIApplication.appBuild, forKey: UserDefaultsKeys.appBuild.rawValue)

        // retrieve value from local store, if value doesn't exist then false is returned
        let hasSetup = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasDoneFirstTimeSetup.rawValue)

        if hasSetup {
            AppDelegate.generalLogger.notice("Recurring setup for app data")
            PersistenceManager.setup(isRecurringSetup: true)
        }
        else {
            AppDelegate.generalLogger.notice("First time setup for app data")
            PersistenceManager.setup()
        }

        // AppDelegate.generalLogger.notice("application end \(UserDefaults.standard.object(forKey: UserDefaultsKeys.dogManager.rawValue) as? Data)")
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        AppDelegate.lifeCycleLogger.notice("Application Will Terminate")
        PersistenceManager.willEnterBackground(isTerminating: true)

    }

}
