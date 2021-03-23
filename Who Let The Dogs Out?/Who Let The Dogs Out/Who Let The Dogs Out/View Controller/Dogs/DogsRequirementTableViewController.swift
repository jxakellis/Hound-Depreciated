//
//  DogsRequirementTableViewController.swift
//  Who Let The Dogs Out
//
//  Created by Jonathan Xakellis on 1/20/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import UIKit

protocol DogsRequirementTableViewControllerDelegate {
    ///When the requirement list is updated, the whole list is pushed through to the DogsAddDogVC, this is much simplier than updating one item at a time, easier for consistant arrays
    func didUpdateRequirements(newRequirementList: [Requirement])
}

class DogsRequirementTableViewController: UITableViewController, RequirementManagerControlFlowProtocol, DogsInstantiateRequirementViewControllerDelegate, DogsRequirementTableViewCellDelegate {
    //MARK: Dogs Requirement Table View Cell
    
    func didToggleEnable(sender: Sender, requirementName: String, newEnableStatus: Bool) {
        let sudoRequirementManager = getRequirementManager()
        do {
           try sudoRequirementManager.findRequirement(requirementName: requirementName).setEnable(newEnableStatus: newEnableStatus)
            setRequirementManager(sender: sender, newRequirementManager: sudoRequirementManager)
        }
        catch {
            fatalError("DogsRequirementTableViewController func didToggleEnable(requirementName: String, newEnableStatus: Bool) error")
        }
        
        
    }
    
    /*
    ///When the trash button is clicked on a cell, triggered through a delegate, this function is called to delete the corrosponding info
    func didClickTrash(dogName: String) {
        do{
            try requirementManager.removeRequirement(requirementName: dogName)
            updateTable()
        }
        catch {
            fatalError("DogsRequirementTableViewController func didClickTrash(dogName: String)")
        }
    }
     */
    
    //MARK: Dogs Instantiate Requirement
    
    var dogsInstantiateRequirementViewController = DogsInstantiateRequirementViewController()
    
    ///When this function is called through a delegate, it adds the information to the list of requirements and updates the cells to display it
    func didAddRequirement(newRequirement: Requirement) throws{
        var sudoRequirementManager = getRequirementManager()
        try sudoRequirementManager.addRequirement(newRequirement: newRequirement)
        setRequirementManager(sender: Sender(origin: self, localized: self), newRequirementManager: sudoRequirementManager)
    }
    
    func didUpdateRequirement(formerName: String, updatedRequirement: Requirement) throws {
        var sudoRequirementManager = getRequirementManager()
        try sudoRequirementManager.changeRequirement(requirementToBeChanged: formerName, newRequirement: updatedRequirement)
        setRequirementManager(sender: Sender(origin: self, localized: self), newRequirementManager: sudoRequirementManager)
    }
    
    @IBAction func unwind(_ seg: UIStoryboardSegue){
        
    }
    
    //MARK: Requirement Manager Control Flow Protocol
    
    private var requirementManager = RequirementManager()
    
    func getRequirementManager() -> RequirementManager {
        return requirementManager.copy() as! RequirementManager
    }
    
    func setRequirementManager(sender: Sender, newRequirementManager: RequirementManager) {
        requirementManager = newRequirementManager.copy() as! RequirementManager
        
        if !(sender.localized is DogsRequirementNavigationViewController){
            delegate.didUpdateRequirements(newRequirementList: getRequirementManager().requirements)
        }
        
        if !(sender.origin is DogsRequirementTableViewCell){
            updateRequirementManagerDependents()
        }
       
    }
    
    func updateRequirementManagerDependents() {
        self.updateTable()
    }
    
    //MARK: Properties
    
    
    
    var delegate: DogsRequirementTableViewControllerDelegate! = nil
    
    //MARK: Main
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorInset = UIEdgeInsets.zero
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.getRequirementManager().requirements.count == 0 {
            self.tableView.allowsSelection = false
        }
        else {
            self.tableView.allowsSelection = true
        }
        
        MainTabBarViewController.mainTabBarViewController.dogsViewController.dogsAddDogViewController.willHideButtons(isHidden: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MainTabBarViewController.mainTabBarViewController.dogsViewController.dogsAddDogViewController.willHideButtons(isHidden: true)
    }
    // MARK: - Table View Data Source
    
    //Number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    ///Returns the number of cells present in section (currently only 1 section)
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if getRequirementManager().requirements.count == 0{
            return 1
        }
        return getRequirementManager().requirements.count
    }
    
    ///Configures cells at the given index path, pulls from requirement manager requirements to get configuration parameters for each cell, corrosponding cell goes to corrosponding index of requirement manager requirement e.g. cell 1 at [0]
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if getRequirementManager().requirements.count == 0{
            let emptyCell = tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
            return emptyCell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "dogsRequirementTableViewCell", for: indexPath)
        
        let castCell = cell as! DogsRequirementTableViewCell
        castCell.delegate = self
        castCell.setup(requirement: getRequirementManager().requirements[indexPath.row])
        
        return cell
    }
    
    ///Reloads table data when it is updated, if you change the data w/o calling this, the data display to the user will not be updated
    private func updateTable(){
        
        if self.getRequirementManager().requirements.count == 0 {
            self.tableView.allowsSelection = false
        }
        else {
            self.tableView.allowsSelection = true
        }
        
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedTuple = (getRequirementManager().requirements[indexPath.row], true)
        
        self.performSegue(withIdentifier: "dogsInstantiateRequirementViewController", sender: self)
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let sudoRequirementManager = getRequirementManager()
        if editingStyle == .delete && sudoRequirementManager.requirements.count > 0{
            sudoRequirementManager.requirements.remove(at: indexPath.row)
            setRequirementManager(sender: Sender(origin: self, localized: self), newRequirementManager: sudoRequirementManager)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.getRequirementManager().requirements.count == 0 {
            return false
        }
        else {
            return true
        }
    }
    
    private var selectedTuple: (Requirement, Bool)? = nil
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Links delegate to instantiateRequirement
        if segue.identifier == "dogsInstantiateRequirementViewController" {
            dogsInstantiateRequirementViewController = segue.destination as! DogsInstantiateRequirementViewController
            dogsInstantiateRequirementViewController.delegate = self
            
            if self.selectedTuple != nil {
                dogsInstantiateRequirementViewController.setupTuple = self.selectedTuple!
                self.selectedTuple = nil
            }
            
        }
    }
    
    
}
