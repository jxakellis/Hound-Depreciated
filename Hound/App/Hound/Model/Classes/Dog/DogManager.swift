//
//  DogManager.swift
//  Hound
//
//  Created by Jonathan Xakellis on 3/21/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import UIKit

class DogManager: NSObject, NSCopying, NSCoding {
    
    // MARK: - NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = DogManager()
        for i in 0..<dogs.count {
            copy.dogs.append(dogs[i].copy() as! Dog)
        }
        return copy
    }
    
    // MARK: - NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        dogs = aDecoder.decodeObject(forKey: "dogs") as? [Dog] ?? []
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(dogs, forKey: "dogs")
    }
    
    // MARK: - Main
    
    /// initalizes, sets dogs to []
    override init() {
        super.init()
    }
    
    convenience init(forDogs dogs: [Dog]) {
        self.init()
        // verifys dogs and fixes if broken
        self.addDogs(newDogs: dogs)
    }
    
    /// Init from an array of dog JSON
    convenience init?(fromBody dogBodies: [[String: Any]]) {
        var dogArray: [Dog] = []
        
        // Array of dog JSON [{dog1:'foo'},{dog2:'bar'}]
        for dogBody in dogBodies {
            let dog = Dog(fromBody: dogBody)
                // If we have an image stored locally for a dog, then we apply the icon.
                // If the dog has no icon (because someone else in the family made it and the user hasn't selected their own icon OR because the user made it and never added an icon) then the dog just gets the defaultDogIcon
                dog.dogIcon = LocalDogIcon.getIcon(forDogId: dog.dogId) ?? DogConstant.defaultDogIcon
                dogArray.append(dog)
        }
        
        self.init(forDogs: dogArray)
    }
    
    /// Stores all the dogs. This is get only to make sure integrite of dogs added is kept
    private(set) var dogs: [Dog] = []
    
    /// Helper function allows us to use the same logic for addDog and addDogs and allows us to only sort at the end. Without this function, addDogs would invoke addDog repeadly and sortDogs() with each call.
    func addDogWithoutSorting(newDog: Dog) {
        // If we discover a newDog has the same dogId as an existing dog, we replace that existing dog with the new dog BUT we first add the existing reminders and logs to the new dog's reminders and logs.
        for (currentDogIndex, currentDog) in dogs.enumerated().reversed() where currentDog.dogId == newDog.dogId {
            // we should combine the currentDog's reminders/logs into the new dog
            newDog.combine(withOldDog: currentDog)
            newDog.dogIcon = currentDog.dogIcon
            dogs.remove(at: currentDogIndex)
            break
        }
        
        dogs.append(newDog)
    }
    
    /// Adds a dog to dogs, checks to see if the dog itself is valid, e.g. its dogId is unique. Currently override other dog with the same dogId
    func addDog(newDog: Dog) {
        
        addDogWithoutSorting(newDog: newDog)
        
        sortDogs()
    }
    
    /// Adds array of dogs with addDog(newDog: Dog) repition  (but only sorts once at the end to be more efficent)
    func addDogs(newDogs: [Dog]) {
        for newDog in newDogs {
            addDogWithoutSorting(newDog: newDog)
        }
        
        sortDogs()
    }
    
    /// Sorts the dogs based upon their dogId
    private func sortDogs() {
        dogs.sort { dog1, dog2 in
            return dog1.dogId <= dog2.dogId
        }
    }
    
    /// Removes a dog with the given dogId
    func removeDog(forDogId dogId: Int) throws {
        var matchingDogIndex: Int?
        
        for (index, dog) in dogs.enumerated() where dog.dogId == dogId {
            matchingDogIndex = index
            // make sure we invalidate all the timers associated. this isn't technically necessary but its easier to tie up lose ends here
            for reminder in dog.dogReminders.reminders {
                reminder.timer?.invalidate()
            }
            break
        }
        
        if matchingDogIndex == nil {
            throw DogManagerError.dogIdNotPresent
        }
        else {
            dogs.remove(at: matchingDogIndex!)
        }
    }
    
    /// Removes a dog at the given index
    func removeDog(forIndex index: Int) {
        // unsafe function
        let dog = dogs[index]
        
        // make sure we invalidate all the timers associated. this isn't technically necessary but its easier to tie up lose ends here
        for reminder in dog.dogReminders.reminders {
            reminder.timer?.invalidate()
        }
        
        dogs.remove(at: index)
    }
    
}

extension DogManager {
    
    // MARK: Locate
    
    /// Returns reference of a dog with the given dogId
    func findDog(forDogId dogId: Int) throws -> Dog {
        for d in 0..<dogs.count where dogs[d].dogId == dogId {
            return dogs[d]
        }
        
        throw DogManagerError.dogIdNotPresent
    }
    
    /// Returns the index of a dog with the given dogId
    func findIndex(forDogId dogId: Int) throws -> Int {
        for d in 0..<dogs.count where dogs[d].dogId == dogId {
            return d
        }
        
        throw DogManagerError.dogIdNotPresent
    }
    
    // MARK: Information
    
    /// Returns true if ANY the dogs present has at least 1 CREATED reminder
    var hasCreatedReminder: Bool {
        for dog in 0..<dogs.count where dogs[dog].dogReminders.reminders.count > 0 {
            return true
        }
        return false
    }
    
    /// Returns true if dogs.count > 0
    var hasCreatedDog: Bool {
        if dogs.count > 0 {
            return true
        }
        else {
            return false
        }
    }
    
    /// Returns true if ANY the dogs present has at least 1 ENABLED reminder
    var hasEnabledReminder: Bool {
        for dog in dogs {
            for reminder in dog.dogReminders.reminders where reminder.reminderIsEnabled == true {
                return true
            }
        }
        return false
    }
    
    /// Returns number of reminders that are enabled and therefore have a timer. Does not factor in isPaused.
    var enabledTimersCount: Int {
        var count = 0
        for d in 0..<MainTabBarViewController.staticDogManager.dogs.count {
            
            for r in 0..<MainTabBarViewController.staticDogManager.dogs[d].dogReminders.reminders.count {
                guard MainTabBarViewController.staticDogManager.dogs[d].dogReminders.reminders[r].reminderIsEnabled == true else {
                    continue
                }
                
                count += 1
            }
        }
        return count
    }
    
    /// Returns an array of tuples [(parentDogId, log]). This array has all the logs for all the dogs sorted chronologically, oldest log at index 0 and newest at end of array. Optionally filters by dictionary literal of [dogIds: [logActions]] provided
    private func logsByDogId(forLogsFilter logsFilter: [Int: [LogAction]]) -> [Int: [Log]] {
        var logsByDogId: [Int: [Log]] = [:]
        
        // no filter was provided, so we add all logs of all dogs
        if logsFilter.isEmpty {
            for dog in dogs {
                logsByDogId[dog.dogId] = dog.dogLogs.logs
            }
        }
        // a filter was provided
        else {
            // search for dogs provided in the filter, as we only want logs from dogs specified in the filter
            for dog in dogs where logsFilter.keys.contains(dog.dogId) {
                // search for dogLogs in the dog. We only want logs that have a logAction which is provided in the filter (under the dogId)
                logsByDogId[dog.dogId] = dog.dogLogs.logs.filter { log in
                    // the filter had the dogId stored, specifiying this dog, and had the logAction stored, specifying all logs of this logAction type. This means we can append the log
                    return logsFilter[dog.dogId]!.contains(log.logAction)
                }
            }
        }
        
        return logsByDogId
    }
    
    /// Returns an array of tuples [(uniqueDay, uniqueMonth, uniqueYear, [(parentDogId, log)])]. This array has all of the logs for all of the dogs grouped what unique day/month/year they occured on, first element is furthest in the future and last element is the oldest. Optionally filters by the dogId and logAction provides
    func groupedLogsByUniqueDate(forLogsFilter logsFilter: [Int: [LogAction]]) -> [(Int, Int, Int, [(Int, Log)])] {
        var dogIdLogsTuples: [(Int, Log)] = []
        // Put all the dogIds and logs into one array
        
        for element in logsByDogId(forLogsFilter: logsFilter) {
            element.value.forEach { log in
                dogIdLogsTuples.append((element.key, log))
            }
        }
        
        // Sort this array chronologically
        dogIdLogsTuples.sort { tuple1, tuple2 in
            let (_, log1) = tuple1
            let (_, log2) = tuple2
            return log1.logDate.distance(to: log2.logDate) <= 0
        }
        
        var groupedLogsByUniqueDate: [(Int, Int, Int, [(Int, Log)])] = []
        
        // we will be going from oldest logs to newest logs (by logDate)
        for element in dogIdLogsTuples {
            let logDay = Calendar.current.component(.day, from: element.1.logDate)
            let logMonth = Calendar.current.component(.month, from: element.1.logDate)
            let logYear = Calendar.current.component(.year, from: element.1.logDate)
            
            let containsDateCombination = groupedLogsByUniqueDate.contains { day, month, year, _ in
                // check to see if that day, month, year comboination is already present
                if day == logDay && month == logMonth && year == logYear {
                    return true
                }
                else {
                    return false
                }
            }
            
            // there is already a tuple with the same day, month, and year, so we want to add this dogId/log combo to the array attached to that tuple
            if containsDateCombination {
                groupedLogsByUniqueDate[groupedLogsByUniqueDate.count - 1].3.append(element)
                
            }
            // in the master array, there is not a matching tuple with the specified day, month, and year, so we should add an element that contains the day, month, and year plus this log since its logDate is on this day, month, and year
            else {
                groupedLogsByUniqueDate.append((logDay, logMonth, logYear, [element]))
            }
        }
        
        // Sort the array so that the the tuples with the dates that are furthest in the future are at the beginning of the array and the oldest are at the end
        groupedLogsByUniqueDate.sort { tuple1, tuple2 in
            let (day1, month1, year1, _) = tuple1
            let (day2, month2, year2, _) = tuple2
            // if the year is bigger and the day is bigger then that comes first (e.g.  (4, 2020) comes first in the array and (2,2020) comes second, so most recent is first)
            if year1 > year2 {
                // Tuple1's year is greater than Tuple2's year, meaning Tuple1 is further in the future and should come first
                return true
            }
            else if year1 == year2 {
                if month1 > month2 {
                    // Tuple1's month is greater than Tuple2's month, meaning Tuple1 is further in the future and should come first
                    return true
                }
                else if month1 == month2 {
                    if day1 >= day2 {
                        // Tuple1's day is greater than Tuple2's days, meaning Tuple1 is further in the future and should come first
                        // we don't care if the days are equal as that case should never happen and, if it does, then the position doesn't matter
                        return true
                    }
                    else {
                        // Tuple1's day is less than Tuple2's days, meaning Tuple2 is further in the future and should come first
                        return false
                    }
                }
                else {
                    // Tuple1's month is less than Tuple2's month, meaning Tuple2 is further in the future and should come first
                    return false
                }
            }
            else {
                // Tuple1's year is less than Tuple2's year, meaning Tuple2 is further in the future should come first
                return false
            }
        }
        
        return groupedLogsByUniqueDate
        
    }
    
    // MARK: Compare
    
    /// Combines all of the dogs, reminders, and logs in union fashion to the dogManager. If a dog, reminder, or log exists in either of the dogManagers, then they will be present after this function is done. Dogs, reminders, or logs in the newDogManager (this object) overwrite dogs, reminders, or logs in the oldDogManager. Note: if one dog is to overwrite another dog, it will first combine the reminder/logs, again the reminders/logs of the newDog will take precident over the reminders/logs of the oldDog.
    func combine(withOldDogManager oldDogManager: DogManager) {
        // the addDogs function overwrites the dog info (e.g. dogName) but combines the reminders / logs in the event that the oldDogManager and the newDogManager both contain a dog with the same dogId. Therefore, we must add the dogs to the oldDogManager (allowing the newDogManager to overwrite the oldDogManager dogs if there is an overlap)
        oldDogManager.addDogs(newDogs: self.dogs)
        // now that the oldDogManager contains its original dogs, our new dogs, and has had its old dogs overwritten (in the case old & new both had a dog with same dogId), we have an updated array.
        self.dogs = oldDogManager.dogs
        sortDogs()
    }
    
}

protocol DogManagerControlFlowProtocol {
    
    /// Returns a copy of DogManager, used to avoid accidental changes (due to reference type) by classes which get their dog manager from here
    func getDogManager() -> DogManager
    
    /// Sets DogManger equal to newDogManager, depending on sender will also call methods to propogate change.
    func setDogManager(sender: Sender, newDogManager: DogManager)
    
}