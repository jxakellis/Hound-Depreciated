//
//  FamilyConfiguration.swift
//  Hound
//
//  Created by Jonathan Xakellis on 4/5/22.
//  Copyright © 2022 Jonathan Xakellis. All rights reserved.
//

import Foundation

/// Configuration that is local to the app only. If the app is reinstalled then this data should be pulled down from the cloud
enum FamilyConfiguration {
    
    // MARK: - Main
    
    /// Sets the FamilyConfiguration values equal to all the values found in the body. The key for the each body value must match the name of the FamilyConfiguration property exactly in order to be used. The value must also be able to be converted into the proper data type.
    static func setup(fromBody body: [String: Any]) {
        if let isLocked = body[ServerDefaultKeys.isLocked.rawValue] as? Bool {
            self.isLocked = isLocked
        }
        if let familyCode = body[ServerDefaultKeys.familyCode.rawValue] as? String {
            self.familyCode = familyCode
        }
        if let isPaused = body[ServerDefaultKeys.isPaused.rawValue] as? Bool {
            self.isPaused = isPaused
        }
        if let familyMembersBody = body[ServerDefaultKeys.familyMembers.rawValue] as? [[String: Any]] {
            familyMembers.removeAll()
            // get individual bodies for members
            for familyMemberBody in familyMembersBody {
                // convert body into family member
                familyMembers.append(FamilyMember(fromBody: familyMemberBody))
            }
            
            // assign familyHead
            if let familyHeadUserId = body[ServerDefaultKeys.userId.rawValue] as? String {
                for familyMember in familyMembers where familyMember.userId == familyHeadUserId {
                    familyMember.isFamilyHead = true
                }
            }
            
            // sort so family head is first then users in ascending userid order
            familyMembers.sort { familyMember1, familyMember2 in
                // the family head should always be first
                if familyMember1.isFamilyHead == true {
                    // 1st element is head so should come before therefore return true
                    return true
                }
                else if familyMember2.isFamilyHead == true {
                    // 2nd element is head so should come before therefore return false
                    return false
                }
                else {
                    // the user with the lower userId should come before the higher id
                    // if familyMember1 has a smaller userId then comparison returns true and then true is returned again, bringing familyMember1 to be first
                    // if familyMember2 has a smaller userId then comparison returns false and then false is returned, bringing familyMember2 to be first
                    return (familyMember1.userId < familyMember2.userId)
                }
            }
        }
    }
    
    // MARK: - Main
    
    /// Saves state isPaused, self.isPaused can be modified by SettingsViewController but this is only when there are no active timers and pause is automatically set to unpaused
    static var isPaused: Bool = false
    
    /// The code used by new users to join the family
    static var familyCode: String = ""
    
    /// If a family is locked, then no new members can join. Only the family head can lock and unlock the family.
    static var isLocked: Bool = false
    
    static var familyMembers: [FamilyMember] = []
   
}