//
//  SettingsViewController.swift
//  Who Let The Dogs Out
//
//  Created by Jonathan Xakellis on 2/5/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate {
    func didTogglePause(newPauseState: Bool)
}

class SettingsViewController: UIViewController {

    var delegate: SettingsViewControllerDelegate! = nil
    
    
    //MARK: Pause All Alarms
    ///Switch for pause all alarms
    @IBOutlet weak var isPaused: UISwitch!
    
    ///If the pause all alarms switch it triggered, calls thing function
    @IBAction func didTogglePause(_ sender: Any) {
        delegate.didTogglePause(newPauseState: isPaused.isOn)
    }
    
    //MARK: Scheduled Pause
    
    @IBOutlet weak var isScheduled: UISwitch!
    
    @IBAction func didToggleSchedule(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
}
