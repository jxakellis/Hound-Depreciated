//
//  UserDefaultKeys.swift
//  Hound
//
//  Created by Jonathan Xakellis on 3/31/22.
//  Copyright © 2022 Jonathan Xakellis. All rights reserved.
//

import Foundation

enum UserDefaultsKeys: String {
    
    // MARK: User Information
    
    // store userId and familyId locally but we still use ServerDefaultKeys
    
    // MARK: User Configuration
    
    // all stored in server, so no user defaults
    
    // MARK: Local Configuration
    case dogIcons
    
    case logCustomActionNames
    case reminderCustomActionNames
    
    case isNotificationAuthorized
    
    case datesUserShownBannerToReviewHound
    case datesUserReviewRequested
    
    case appVersionsWithReleaseNotesShown
    case appBuildsWithReleaseNotesShown
    
    case hasLoadedHoundIntroductionViewControllerBefore
    case hasLoadedRemindersIntroductionViewControllerBefore
    case hasLoadedSettingsFamilyIntroductionViewControllerBefore
    
    // MARK: Other
    case hasDoneFirstTimeSetup
    case appVersion
    case appBuild
}
