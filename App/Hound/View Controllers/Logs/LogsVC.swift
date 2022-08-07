//
//  LogsViewController.swift
//  Hound
//
//  Created by Jonathan Xakellis on 4/17/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import UIKit

protocol LogsViewControllerDelegate: AnyObject {
    func didUpdateDogManager(sender: Sender, forDogManager: DogManager)
}

final class LogsViewController: UIViewController, UIGestureRecognizerDelegate, DogManagerControlFlowProtocol, LogsTableViewControllerDelegate, DropDownUIViewDataSource, LogsAddLogViewControllerDelegate {

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // MARK: - LogsAddLogViewControllerDelegate

    func didAddLog(sender: Sender, parentDogId: Int, newLog: Log) {
        
        if dogManager.dogs.isEmpty == false {
            do {
                try dogManager.findDog(forDogId: parentDogId).dogLogs.addLog(forLog: newLog)
            }
            catch {
                ErrorManager.alert(forError: error)
            }

        }
        setDogManager(sender: sender, forDogManager: dogManager)

        CheckManager.checkForReview()
    }

    func didUpdateLog(sender: Sender, parentDogId: Int, updatedLog: Log) {

        if dogManager.dogs.isEmpty == false, let dog = try? dogManager.findDog(forDogId: parentDogId) {
                
             dog.dogLogs.addLog(forLog: updatedLog)

         }

         setDogManager(sender: sender, forDogManager: dogManager)

        CheckManager.checkForReview()

    }

    func didRemoveLog(sender: Sender, parentDogId: Int, logId: Int) {
        
        guard let dog = try? dogManager.findDog(forDogId: parentDogId) else {
            return
        }

        for dogLogIndex in 0..<dog.dogLogs.logs.count where dog.dogLogs.logs[dogLogIndex].logId == logId {
            dog.dogLogs.removeLog(forIndex: dogLogIndex)
            break
        }

        setDogManager(sender: sender, forDogManager: dogManager)

        CheckManager.checkForReview()
    }

    // MARK: - LogsTableViewControllerDelegate

    func didUpdateDogManager(sender: Sender, forDogManager: DogManager) {
        setDogManager(sender: sender, forDogManager: forDogManager)
    }

    /// Log selected in the main table view of the logs of care page. This log object has JUST been retrieved and constructed from data from the server.
    private var selectedLog: Log?
    /// Parent dog id of the log selected in the main table view of the logs of care page.
    private var parentDogIdOfSelectedLog: Int?

    func didSelectLog(parentDogId: Int, log: Log) {
        selectedLog = log
        parentDogIdOfSelectedLog = parentDogId
        self.performSegueOnceInWindowHierarchy(segueIdentifier: "logsAddLogViewController")
        selectedLog = nil
        parentDogIdOfSelectedLog = nil
    }

    // MARK: - DogManagerControlFlowProtocol

    private var dogManager: DogManager = DogManager()

    func setDogManager(sender: Sender, forDogManager: DogManager) {
         dogManager = forDogManager

        // we dont want to update LogsTableViewController if its the one providing the update
        if (sender.localized is LogsTableViewController) == false {
            // need to update table view
            logsTableViewController?.setDogManager(sender: Sender(origin: sender, localized: self), forDogManager: dogManager)
            
            // logs modified have been added so we need to reset the filter. Note: setting the dogManager of logsTableViewController automatically clears the logsFilter, so don't invoke the log filter method
            logsFilter = [:]
        }
        // we dont want to update MainTabBarViewController with the delegate if its the one providing the update
        if (sender.localized is MainTabBarViewController) == false {
            delegate.didUpdateDogManager(sender: Sender(origin: sender, localized: self), forDogManager: dogManager)
        }
        if (sender.localized is MainTabBarViewController) == true {
            // pop add log vc as the dog it could have been adding to is now deleted
            logsAddLogViewController?.navigationController?.popViewController(animated: false)
        }
    }

    // MARK: - IB

    @IBOutlet private weak var containerView: UIView!
    
    @IBOutlet private weak var filterButton: UIBarButtonItem!

    @IBOutlet private weak var refreshButton: UIBarButtonItem!
    
    @IBAction private func willRefresh(_ sender: Any) {
        self.refreshButton.isEnabled = false
        ActivityIndicator.shared.beginAnimating(title: navigationItem.title ?? "", view: self.view, navigationItem: navigationItem)
        
        RequestUtils.getFamilyGetDog(invokeErrorManager: true, dogManager: dogManager) { newDogManager, _ in
            self.refreshButton.isEnabled = true
            ActivityIndicator.shared.stopAnimating(navigationItem: self.navigationItem)
            
            guard let newDogManager = newDogManager else {
                return
            }
            
            self.performSpinningCheckmarkAnimation()
            self.setDogManager(sender: Sender(origin: self, localized: self), forDogManager: newDogManager)
        }
        
    }
    @IBOutlet private weak var willAddLog: ScaledUIButton!
    @IBOutlet private weak var willAddLogBackground: ScaledUIButton!

    @IBAction private func willShowFilter(_ sender: Any) {

        var numRowsDisplayed: Int {

            // finds the total count of rows needed
            var totalCount: Int {
                var count = 0
                for dog in dogManager.dogs {
                    count += dog.dogLogs.uniqueLogActions.count + 1
                }

                if count == 0 {
                    return 1
                }
                return count + 1
            }

            // finds the total number of rows that can be displayed and makes sure that the needed does not exceed that
            let maximumHeight = self.view.safeAreaLayoutGuide.layoutFrame.size.height
            let neededHeight = DropDownUIView.rowHeightForLogFilter * CGFloat(totalCount)

            if neededHeight < maximumHeight {
                return totalCount
            }
            else {
                return Int((maximumHeight / DropDownUIView.rowHeightForLogFilter).rounded(.down))
            }

        }
        dropDown.showDropDown(numberOfRowsToShow: CGFloat(numRowsDisplayed))
    }

    // MARK: - Properties

    private let dropDown = DropDownUIView()

    // Dictionary literal the currently applied logsFilter. [ "currentDogId" : ["filterByAction1","filterByAction2"]]. Filters by selected actions under selected dogs. Note: if the dictionary literal is empty, then shows all
    private var logsFilter: [Int: [LogAction]] = [:]

    var logsTableViewController: LogsTableViewController! = nil

    var logsAddLogViewController: LogsAddLogViewController?

    weak var delegate: LogsViewControllerDelegate! = nil

    // MARK: - Main

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.bringSubviewToFront(willAddLog)
        
        // TO DO FUTURE add export logs button 

        let tap = UITapGestureRecognizer(target: self, action: #selector(hideDropDown))
        tap.delegate = self
        tap.cancelsTouchesInView = false
        containerView.addGestureRecognizer(tap)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AlertManager.globalPresenter = self

        filterButton.isEnabled = !dogManager.dogs.isEmpty
        willAddLog?.isHidden = dogManager.dogs.isEmpty
        willAddLogBackground?.isHidden = dogManager.dogs.isEmpty
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupDropDown()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dropDown.hideDropDown(removeFromSuperview: true)
    }

    // MARK: - Drop Down Functions

    private func setupDropDown() {

        /// Finds the widthNeeded by the largest label, has a minimum and maximum possible along with subtracting the space taken by leading and trailing constraints.
        var neededWidthForLabel: CGFloat {
            let maximumWidth: CGFloat = view.safeAreaLayoutGuide.layoutFrame.width - 24.0
            let minimumWidth: CGFloat = 100.0 - 24.0

            /// Finds the largestWidth taken up by any label, later compared to constraint sizes of min and max. Leading and trailing constraints not considered here, that will be adjusted later
            var largestLabelWidth: CGFloat {

                var largest: CGFloat = "Clear Filter".boundingFrom(font: VisualConstant.FontConstant.filterByDogFont, height: DropDownUIView.rowHeightForLogFilter).width

                for dog in dogManager.dogs {
                    let dogNameWidth = dog.dogName.boundingFrom(font: VisualConstant.FontConstant.filterByDogFont, height: DropDownUIView.rowHeightForLogFilter).width

                    if dogNameWidth > largest {
                        largest = dogNameWidth
                    }

                    for uniqueLogAction in dog.dogLogs.uniqueLogActions {
                        let logActionWidth = uniqueLogAction.rawValue.boundingFrom(font: VisualConstant.FontConstant.filterByLogFont, height: DropDownUIView.rowHeightForLogFilter).width

                        if logActionWidth > largest {
                            largest = logActionWidth
                        }

                    }
                }

                return largest
            }

            switch largestLabelWidth {
            case 0..<minimumWidth:
                return minimumWidth
            case minimumWidth...maximumWidth:
                return largestLabelWidth.rounded(.up)
            default:
                return maximumWidth
            }
        }

        /// only one dropdown used on the dropdown instance so no identifier needed
        dropDown.dropDownUIViewIdentifier = ""
        dropDown.cellReusableIdentifier = "dropDownCell"
        dropDown.dataSource = self
        dropDown.setupDropDown(viewPositionReference: (CGRect(origin: self.view.safeAreaLayoutGuide.layoutFrame.origin, size: CGSize(width: neededWidthForLabel + (DropDownUIView.insetForLogFilter * 2), height: 0.0))), offset: 0.0)
        dropDown.nib = UINib(nibName: "DropDownLogFilterTableViewCell", bundle: nil)
        dropDown.setRowHeight(height: DropDownUIView.rowHeightForLogFilter)
        self.view.addSubview(dropDown)
    }

    @objc private func hideDropDown() {
        dropDown.hideDropDown()
    }
    
    // MARK: - Drop Down Functions Data Source
    
    func setupCellForDropDown(cell: UITableViewCell, indexPath: IndexPath, dropDownUIViewIdentifier: String) {
        
        let customCell = cell as! DropDownLogFilterTableViewCell
        
        // clear filter
        if indexPath.section == dogManager.dogs.count {
            customCell.setup(forDog: nil, forLogAction: nil)
        }
        else {
            let dog = dogManager.dogs[indexPath.section]
            // dog name header
            if indexPath.row == 0 {
                customCell.setup(forDog: dog, forLogAction: nil)
            }
            // dog log filter
            else {
                customCell.setup(forDog: dog, forLogAction: dog.dogLogs.uniqueLogActions[indexPath.row-1])
            }
        }
        
        // check to see if the cell is a "Clear Filter" cell, if it is, then set it to not selected and return
        guard customCell.dogId != nil else {
            customCell.willToggleDropDownSelection(forSelected: false)
            return
        }
        
        for dogId in logsFilter.keys where dogId == customCell.dogId {
            // the cell has a dogId and no logAction so is displaying a dogName. Its dogId is in the logsFilter dictionary, we can select the cell as that dog is selected
            if customCell.logAction == nil {
                customCell.willToggleDropDownSelection(forSelected: true)
                return
            }
            
            // the cell has a logAction, check to see if that logAction is in the filter dictionary. if it is, then we select the cell and return
            let logActions = logsFilter[dogId]!
            
            for logAction in logActions where logAction == customCell.logAction {
                // the cell has a dogId and a logAction that match the filter dictionary, therefore we can select the cell
                customCell.willToggleDropDownSelection(forSelected: true)
                return
            }
        }
        
        // the cell didn't match any conditions above, so set it as not selected
        customCell.willToggleDropDownSelection(forSelected: false)
    }
    
    func numberOfRows(forSection section: Int, dropDownUIViewIdentifier: String) -> Int {
        
        guard dogManager.dogs.isEmpty == false else {
            return 1
        }
        // We are on the last section. This one is reserved for "Clear Filter"
        if section == dogManager.dogs.count {
            return 1
        }
        // Regular section, corresponds to a dog
        else {
            // A row for the dogName and rows for all of the logActions
            return dogManager.dogs[section].dogLogs.uniqueLogActions.count + 1
        }
        
    }
    
    func numberOfSections(dropDownUIViewIdentifier: String) -> Int {
         // We add an extra section for the "Clear Filter" text at the end
        return dogManager.dogs.count + 1
    }
    
    func selectItemInDropDown(indexPath: IndexPath, dropDownUIViewIdentifier: String) {
        let selectedCell = dropDown.dropDownTableView!.cellForRow(at: indexPath) as! DropDownLogFilterTableViewCell
        // flip isSelectedInDropDown status
        selectedCell.willToggleDropDownSelection(forSelected: !selectedCell.isSelectedInDropDown)
        
        // dog log filter was selected
        if selectedCell.dogId != nil && selectedCell.logAction != nil {
            // find any preexisting logActions that we are filtering by
            var existingLogActionFilters: [LogAction] = logsFilter[selectedCell.dogId!] ?? []
            
            // the cell is now selected, add logAction to logsFilter array
            if selectedCell.isSelectedInDropDown {
                // add additional logAction to filter by
                existingLogActionFilters.append(selectedCell.logAction!)
                // assign array to dogId
                logsFilter[selectedCell.dogId!] = existingLogActionFilters
                
                // Check to see if we just added the first logAction filter for a certain dog
                if existingLogActionFilters.count == 1 {
                    // this is the first logAction selected under the dog. Therefore, the dog cell won't be selected. Therefore, we have to select the dog cell
                    let dogCell = dropDown.dropDownTableView!.cellForRow(at: IndexPath(row: 0, section: indexPath.section)) as! DropDownLogFilterTableViewCell
                    dogCell.willToggleDropDownSelection(forSelected: true)
                }
            }
            // cell is now unselected, remove logAction from logsFilter array
            else {
                // find index of logAction to remove from logsFilter array
                let indexToRemove = existingLogActionFilters.firstIndex(of: selectedCell.logAction!)
                
                guard let indexToRemove = indexToRemove else {
                    return
                }
                // remove logAction from logsFilter array
                existingLogActionFilters.remove(at: indexToRemove)
                // assign array to dogId
                logsFilter[selectedCell.dogId!] = existingLogActionFilters
                
                // check to see if we removed the the last logAction.
                if existingLogActionFilters.count == 0 {
                    // We removed the last logAction for a dog. Remove the logsFilter key and unselect the dog
                    logsFilter[selectedCell.dogId!] = nil
                    let dogCell = dropDown.dropDownTableView!.cellForRow(at: IndexPath(row: 0, section: indexPath.section)) as! DropDownLogFilterTableViewCell
                    dogCell.willToggleDropDownSelection(forSelected: false)
                }
            }
        }
        // dog fitler was selected
        else if selectedCell.dogId != nil {
            let dog = try? dogManager.findDog(forDogId: selectedCell.dogId!)
            
            guard let dog = dog else {
                return
            }
            
            // the dog filter is now selected, make sure every logAction under it is also selected and added to the filter array
            if selectedCell.isSelectedInDropDown {
                // make array of logActions to filter by
                // assign array to dogId, so logsFilter array is updated
                logsFilter[selectedCell.dogId!] = dog.dogLogs.uniqueLogActions
                
                // now select all the logAction cells (we have 1 dogCell and x logAction rows, so subtract 1 to correct the count)
                let numberOfLogActionRows = numberOfRows(forSection: indexPath.section, dropDownUIViewIdentifier: "") - 1
                for logActionRow in 0..<numberOfLogActionRows {
                    // shift logActionRow by 1, as first row cell is a dogCell so we select the proper cell
                    let logActionCell = dropDown.dropDownTableView!.cellForRow(at: IndexPath(row: logActionRow + 1, section: indexPath.section)) as! DropDownLogFilterTableViewCell
                    logActionCell.willToggleDropDownSelection(forSelected: true)
                }
            }
            // the dog filter is now unselected, make sure every logAction under it is also unselcted
            else {
                // clear logsFilter array
                logsFilter[selectedCell.dogId!] = nil
                
                // deselect all the logAction cells (we have 1 dogCell and x logAction rows, so subtract 1 to correct the count)
                let numberOfLogActionRows = numberOfRows(forSection: indexPath.section, dropDownUIViewIdentifier: "") - 1
                for logActionRow in 0..<numberOfLogActionRows {
                    // shift logActionRow by 1, as first row cell is a dogCell so we select the proper cell
                    let logActionCell = dropDown.dropDownTableView!.cellForRow(at: IndexPath(row: logActionRow + 1, section: indexPath.section)) as! DropDownLogFilterTableViewCell
                    logActionCell.willToggleDropDownSelection(forSelected: false)
                }
            }
        }
        // "Clear Filter" row was selected
        else {
            logsFilter = [:]
            
            // deselect all the dog and logAction cells
            let numberOfDogSections = numberOfSections(dropDownUIViewIdentifier: "") - 1
            // go through all of the dog sections
            for dogSection in 0..<numberOfDogSections {
                let numberOfRows = numberOfRows(forSection: dogSection, dropDownUIViewIdentifier: "")
                
                // for each dog section, go through both the dog and logAction cells
                for cellRow in 0..<numberOfRows {
                    let cell = dropDown.dropDownTableView!.cellForRow(at: IndexPath(row: cellRow, section: dogSection)) as! DropDownLogFilterTableViewCell
                    cell.willToggleDropDownSelection(forSelected: false)
                }
            }
            
            dropDown.hideDropDown()
        }
        
        logsTableViewController.willApplyFiltering(forLogsFilter: logsFilter)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logsTableViewController"{
            logsTableViewController = segue.destination as? LogsTableViewController
            logsTableViewController.setDogManager(sender: Sender(origin: self, localized: self), forDogManager: dogManager)
            logsTableViewController.delegate = self
        }
        else if segue.identifier == "logsAddLogViewController"{
            logsAddLogViewController = segue.destination as? LogsAddLogViewController

            logsAddLogViewController!.parentDogIdToUpdate = parentDogIdOfSelectedLog
            logsAddLogViewController!.logToUpdate = selectedLog
            logsAddLogViewController!.dogManager = dogManager
            logsAddLogViewController!.delegate = self
        }
    }

}