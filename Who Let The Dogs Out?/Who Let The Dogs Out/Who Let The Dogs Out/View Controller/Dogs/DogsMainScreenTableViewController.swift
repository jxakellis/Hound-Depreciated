//
//  DogsMainScreenTableViewController.swift
//  Who Let The Dogs Out
//
//  Created by Jonathan Xakellis on 2/1/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import UIKit

protocol DogsMainScreenTableViewControllerDelegate{
    func didSelectDog(indexPathSection dogIndex: Int)
    func didSelectRequirement(indexPathSection dogIndex: Int, indexPathRow requirementIndex: Int)
    func didUpdateDogManager(sender: Sender, newDogManager: DogManager)
}

class DogsMainScreenTableViewController: UITableViewController, DogManagerControlFlowProtocol, DogsMainScreenTableViewCellDogDisplayDelegate, DogsMainScreenTableViewCellRequirementDisplayDelegate {
    
    //MARK: DogsMainScreenTableViewCellDogDisplayDelegate
    
    ///Dog switch is toggled in DogsMainScreenTableViewCellDogDisplay
    func didToggleDogSwitch(sender: Sender, dogName: String, isEnabled: Bool) {
        
        let sudoDogManager = getDogManager()
        try! sudoDogManager.findDog(dogName: dogName).setEnable(newEnableStatus: isEnabled)
        
        setDogManager(sender: sender, newDogManager: sudoDogManager)
        
        //This is so the cell animates the changing of the switch properly, if this code wasnt implemented then when the table view is reloaded a new batch of cells is produced and that cell has the new switch state, bypassing the animation as the instantant the old one is switched it produces and shows the new switch
        let indexPath = try! IndexPath(row: 0, section: getDogManager().findIndex(dogName: dogName))
        
        let cell = tableView.cellForRow(at: indexPath) as! DogsMainScreenTableViewCellDogDisplay
        cell.dogToggleSwitch.isOn = !isEnabled
        cell.dogToggleSwitch.setOn(isEnabled, animated: true)
    }
    
    //MARK: DogsMainScreenTableViewCellRequirementDelegate
    
    ///Requirement switch is toggled in DogsMainScreenTableViewCellRequirement
    func didToggleRequirementSwitch(sender: Sender, parentDogName: String, requirementName: String, isEnabled: Bool) {
        
        let sudoDogManager = getDogManager()
        try! sudoDogManager.findDog(dogName: parentDogName).dogRequirments.findRequirement(requirementName: requirementName).setEnable(newEnableStatus: isEnabled)
        
        setDogManager(sender: sender, newDogManager: sudoDogManager)
        
        //This is so the cell animates the changing of the switch properly, if this code wasnt implemented then when the table view is reloaded a new batch of cells is produced and that cell has the new switch state, bypassing the animation as the instantant the old one is switched it produces and shows the new switch
        let indexPath = try! IndexPath(row: getDogManager().findDog(dogName: parentDogName).dogRequirments.findIndex(requirementName: requirementName)+1, section: getDogManager().findIndex(dogName: parentDogName))
        
        let cell = tableView.cellForRow(at: indexPath) as! DogsMainScreenTableViewCellRequirementDisplay
        cell.requirementToggleSwitch.isOn = !isEnabled
        cell.requirementToggleSwitch.setOn(isEnabled, animated: true)
    }
    
    //MARK: Properties
    
    var delegate: DogsMainScreenTableViewControllerDelegate! = nil
    
    var updatingSwitch: Bool = false
    
    //MARK: DogManagerControlFlowProtocol
    
    private var dogManager: DogManager = DogManager()
    
    func getDogManager() -> DogManager {
        return dogManager.copy() as! DogManager
    }
    
    func setDogManager(sender: Sender, newDogManager: DogManager){
        dogManager = newDogManager.copy() as! DogManager
        
        //possible senders
        //DogsRequirementTableViewCell
        //DogsMainScreenTableViewCellDogDisplay
        //DogsViewController
        if !(sender.localized is DogsViewController){
            delegate.didUpdateDogManager(sender: Sender(origin: sender, localized: self), newDogManager: getDogManager())
        }
        if !(sender.origin is DogsMainScreenTableViewController){
            self.updateDogManagerDependents()
        }
        
        updateTableConstraints()
    }
    
    private func updateTableConstraints(){
        if getDogManager().dogs.count > 0 {
            tableView.allowsSelection = true
            self.tableView.rowHeight = -1.0
        }
        else{
            tableView.allowsSelection = false
            self.tableView.rowHeight = 65.5
        }
    }
    
    //Updates different visual aspects to reflect data change of dogManager
    func updateDogManagerDependents(){
        self.updateTable()
    }
    
    //MARK: Main
    
    override func viewDidLoad() {
        self.dogManager = MainTabBarViewController.staticDogManager
        super.viewDidLoad()
        
        if getDogManager().dogs.count == 0 {
            tableView.allowsSelection = false
        }
        
        tableView.separatorInset = UIEdgeInsets.zero
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateTable()
    }
    
    private func updateTable(){
        self.tableView.reloadData()
    }
    
    // MARK: Table View Management
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        //if getDogManager().dogs.count == 0 {
        //    return 1
        //}
        return getDogManager().dogs.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if getDogManager().dogs.count == 0 {
            return 1
        }
        
        return getDogManager().dogs[section].dogRequirments.requirements.count+1
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "dogsMainScreenTableViewCellDogDisplay", for: indexPath)
            
            let testCell = cell as! DogsMainScreenTableViewCellDogDisplay
            testCell.setup(dogPassed: getDogManager().dogs[indexPath.section])
            testCell.delegate = self
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dogsMainScreenTableViewCellRequirementDisplay", for: indexPath)
            
            let testCell = cell as! DogsMainScreenTableViewCellRequirementDisplay
            testCell.setup(parentDogName: getDogManager().dogs[indexPath.section].dogTraits.dogName, requirementPassed: getDogManager().dogs[indexPath.section].dogRequirments.requirements[indexPath.row-1])
            testCell.delegate = self
            return cell
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if getDogManager().dogs.count > 0 {
            if indexPath.row == 0{
                delegate.didSelectDog(indexPathSection: indexPath.section)
                
            }
            else if indexPath.row > 0 {
                delegate.didSelectRequirement(indexPathSection: indexPath.section, indexPathRow: indexPath.row-1)
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && getDogManager().dogs.count > 0 {
            let sudoDogManager = getDogManager()
            if indexPath.row > 0 {
                sudoDogManager.dogs[indexPath.section].dogRequirments.requirements.remove(at: indexPath.row-1)
                setDogManager(sender: Sender(origin: self, localized: self), newDogManager: sudoDogManager)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            else {
                sudoDogManager.dogs.remove(at: indexPath.section)
                setDogManager(sender: Sender(origin: self, localized: self), newDogManager: sudoDogManager)
                self.tableView.deleteSections([indexPath.section], with: .automatic)
            }
            
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.getDogManager().dogs.count == 0 {
            return false
        }
        else {
            return true
        }
    }
    
}
