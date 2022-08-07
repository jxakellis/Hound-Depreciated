//
//  LogsTableViewController.swift
//  Hound
//
//  Created by Jonathan Xakellis on 4/17/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import UIKit

protocol LogsTableViewControllerDelegate: AnyObject {
    func didUpdateDogManager(sender: Sender, forDogManager: DogManager)
    func didSelectLog(parentDogId: Int, log: Log)
}

final class LogsTableViewController: UITableViewController, DogManagerControlFlowProtocol {
    
    // MARK: - DogManagerControlFlowProtocol
    
    private var dogManager: DogManager = DogManager()
    
    func setDogManager(sender: Sender, forDogManager: DogManager) {
        dogManager = forDogManager
        
        if !(sender.localized is LogsTableViewController) {
            // if something external made changes (i.e. not having a user swipe on the table view), we should clear the filter as external changes could have made filter invalid
            // If the view is currently visible, then we instantly reload the data. If it isn't then we indicate that the data should be reloaded next time the view appears
            if isViewLoaded && view.window != nil {
                willApplyFiltering(forLogsFilter: [:])
            }
            else {
                tableViewDataSourceHasBeenUpdated = true
            }
        }
        else {
            delegate.didUpdateDogManager(sender: Sender(origin: sender, localized: self), forDogManager: dogManager)
            self.reloadTableDataSource()
        }
        
    }
    
    // MARK: - Properties
    
    /// Array of tuples [(uniqueDay, uniqueMonth, uniqueYear, [(parentDogId, log)])]. This array has all of the logs for all of the dogs grouped what unique day/month/year they occured on, first element is furthest in the future and last element is the oldest. Optionally filters by the dogId and logAction provides IMPORTANT IMPORTANT IMPORTANT to store this value so we don't recompute more than needed
    private var groupedLogsByUniqueDate: [(Int, Int, Int, [(Int, Log)])] = []
    
    private var logsFilter: [Int: [LogAction]] = [:]
    
    /// used for determining if logs interface scale was changed and if the table view needs reloaded
    private var storedLogsInterfaceScale: LogsInterfaceScale = UserConfiguration.logsInterfaceScale
    
    /// used for determing if the maximumNumberOfLogsDisplayed was changed and if the table view needs reloaded
    private var storedMaximumNumberOfLogsDisplayed: Int = UserConfiguration.maximumNumberOfLogsDisplayed
    
    /// We only want to refresh the tableViewDataSource when the viewController is visible. Otherwise, its a drain on resources to perform all of these calculations
    private var tableViewDataSourceHasBeenUpdated: Bool = false
    
    weak var delegate: LogsTableViewControllerDelegate! = nil
    
    // MARK: - Main
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsSelection = true
        self.tableView.separatorInset = .zero
        // allow for refreshing of the information from the server
        self.tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if tableViewDataSourceHasBeenUpdated {
            // Clears filter and reloads the table
            tableViewDataSourceHasBeenUpdated = false
            willApplyFiltering(forLogsFilter: [:])
        }
        else if storedLogsInterfaceScale != UserConfiguration.logsInterfaceScale {
            storedLogsInterfaceScale = UserConfiguration.logsInterfaceScale
            // Leaves filter alone and reloads table
            reloadTable()
        }
        else if storedMaximumNumberOfLogsDisplayed != UserConfiguration.maximumNumberOfLogsDisplayed {
            storedMaximumNumberOfLogsDisplayed = UserConfiguration.maximumNumberOfLogsDisplayed
            // Leaves filter alone and reloads table
            reloadTable()
        }
        
    }
    /// Makes a query to the server to retrieve new information then refreshed the tableView
    @objc private func refreshTable() {
        RequestUtils.getFamilyGetDog(invokeErrorManager: true, dogManager: dogManager) { newDogManager, _ in
            // end refresh first otherwise there will be a weird visual issue
            self.tableView.refreshControl?.endRefreshing()
            
            guard let newDogManager = newDogManager else {
                return
            }

            self.setDogManager(sender: Sender(origin: self, localized: self), forDogManager: newDogManager)
            // manually reload table as the self sender doesn't do that
            self.tableView.reloadData()
        }
    }
    
    /// Updates dogManagerDependents then reloads table
    private func reloadTable() {
        
        reloadTableDataSource()
        
        tableView.reloadData()
    }
    
    private func reloadTableDataSource() {
        
        // important to store this value so we don't recompute more than needed
        groupedLogsByUniqueDate = dogManager.groupedLogsByUniqueDate(forLogsFilter: logsFilter, forMaximumNumberOfLogsPerDog: UserConfiguration.maximumNumberOfLogsDisplayed)
        
        if groupedLogsByUniqueDate.count == 0 {
            tableView.separatorStyle = .none
        }
        else {
            tableView.separatorStyle = .singleLine
        }
    }
    
    /// Will apply a filtering scheme dependent on indexPath, nil means going to no filtering.
    func willApplyFiltering(forLogsFilter logsFilter: [Int: [LogAction]]) {
        
        self.logsFilter = logsFilter
        
        reloadTable()
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if groupedLogsByUniqueDate.count == 0 {
            return 1
        }
        else {
            return groupedLogsByUniqueDate.count
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if groupedLogsByUniqueDate.count == 0 {
            return 1
            
        }
        else {
            // find the number of logs for a given unique day/month/year, then add 1 for the header that says the day/month/year
            return groupedLogsByUniqueDate[section].3.count + 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var shouldShowFilterIndicator: Bool {
            if indexPath.section == 0 && logsFilter != [:] {
                return true
            }
            else {
                return false
            }
        }
        
        // no logs present
        if groupedLogsByUniqueDate.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "logsHeaderTableViewCell", for: indexPath)
            
            let customCell = cell as! LogsHeaderTableViewCell
            customCell.setup(fromDate: nil, shouldShowFilterIndictator: shouldShowFilterIndicator)
            
            return cell
        }
        // logs are present and need a header (row being zero indicates that the cell is a header)
        else if indexPath.row == 0 {
            
            let nestedLogsArray: [(Int, Log)] = groupedLogsByUniqueDate[indexPath.section].3
            
            // For the given parent array, we will take the first log in the nested array. The header will extract the date information from that log. It doesn't matter which log we take as all logs will have the same day, month, and year since they were already sorted to be in that array.
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "logsHeaderTableViewCell", for: indexPath)
            
            let customCell = cell as! LogsHeaderTableViewCell
            customCell.setup(fromDate: nestedLogsArray[0].1.logDate, shouldShowFilterIndictator: shouldShowFilterIndicator)
            
            return cell
        }
        // log
        else {
            
            let nestedLogsArray: [(Int, Log)] =  groupedLogsByUniqueDate[indexPath.section].3
            
            // indexPath.row -1 corrects for the first row in the section being the header
            let targetTuple = nestedLogsArray[indexPath.row-1]
            let dog = try! dogManager.findDog(forDogId: targetTuple.0)
            let log = targetTuple.1
            
            // has dogIcon
            if dog.dogIcon.isEqualToImage(image: ClassConstant.DogConstant.defaultDogIcon) == false {
                let cell = tableView.dequeueReusableCell(withIdentifier: "logsBodyWithIconTableViewCell", for: indexPath)
                
                let customCell = cell as! LogsBodyWithIconTableViewCell
                customCell.setup(forParentDogIcon: dog.dogIcon, forLog: log)
                
                return cell
            }
            // no dogIcon
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "logsBodyWithoutIconTableViewCell", for: indexPath)
                
                let customCell = cell as! LogsBodyWithoutIconTableViewCell
                customCell.setup(forParentDogName: dog.dogName, forLog: log)
                
                return cell
            }
            
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // can rows that aren't header (header at .row == 0)
        if indexPath.row != 0 {
            return true
        }
        else {
            return false
        }
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        
        // identify components needed to remove data
        
        // let originalNumberOfSections = groupedLogsByUniqueDate.count
        
        let nestedLogsArray = groupedLogsByUniqueDate[indexPath.section].3
        let parentDogId = nestedLogsArray[indexPath.row-1].0
        let logId = nestedLogsArray[indexPath.row-1].1.logId
        
        LogsRequest.delete(invokeErrorManager: true, forDogId: parentDogId, forLogId: logId) { requestWasSuccessful, _ in
            guard requestWasSuccessful, let dog = try? self.dogManager.findDog(forDogId: parentDogId) else {
                return
            }
            
            // Remove the row from the data source
            // find log in dog and remove
            for dogLogIndex in 0..<dog.dogLogs.logs.count where dog.dogLogs.logs[dogLogIndex].logId == logId {
                dog.dogLogs.removeLog(forIndex: dogLogIndex)
                break
            }
            
            self.setDogManager(sender: Sender(origin: self, localized: self), forDogManager: self.dogManager)
            
            // manually reload table as the self sender doesn't do that
            self.tableView.reloadData()
            
            // TO DO BUG, if the number of logs that exist is greater than the logsTableViewControllermaximumNumberOfLogsDisplayed, then when one log gets deleted, another will take its place. This will cause a crash as the tableView is expecting there to be one less row but there is the same amount still. Solution is to probably insert the new row using the tableView.insert thing at the same time we delete.
            /*
            // batch update so doesn't freak out
            tableView.performBatchUpdates {
                
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                var shouldShowFilterIndicator: Bool {
                    if indexPath.section == 0 && self.logsFilter != [:] {
                        return true
                    }
                    else {
                        return false
                    }
                }
                
                // removed final log and must update header (no logs are left at all)
                if self.groupedLogsByUniqueDate.count == 0 {
                    
                    let headerCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! LogsHeaderTableViewCell
                    headerCell.setup(fromDate: nil, shouldShowFilterIndictator: shouldShowFilterIndicator)
                }
                // removed final log of a given section and must remove all headers and body in that now gone-from-the-data section
                else if originalNumberOfSections != self.groupedLogsByUniqueDate.count {
                    tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
                    
                    // removed section that has filter indicator
                    if indexPath.section == 0 && self.groupedLogsByUniqueDate.count >= 1 {
                        // for whatever header will be at the top (section 1 currently but will soon be section 0) the filter indicator will be shown if calculated shouldShowFilterIndicator returnd true (! converts to proper isHidden:)
                        
                        let headerCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! LogsHeaderTableViewCell
                        headerCell.filterImageView.isHidden = !shouldShowFilterIndicator
                    }
                    
                }
            }
            */
            
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nestedLogsArray = groupedLogsByUniqueDate[indexPath.section].3
        let dogId = nestedLogsArray[indexPath.row-1].0
        let logId = nestedLogsArray[indexPath.row-1].1.logId
        
        RequestUtils.beginRequestIndictator()
        LogsRequest.get(invokeErrorManager: true, forDogId: dogId, forLogId: logId) { log, _ in
            RequestUtils.endRequestIndictator {
                self.tableView.deselectRow(at: indexPath, animated: true)
                
                if let log = log {
                    self.delegate.didSelectLog(parentDogId: dogId, log: log)
                }
            }
        }
    }
    
}