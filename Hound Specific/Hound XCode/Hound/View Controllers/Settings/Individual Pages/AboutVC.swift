//
//  SettingsAboutViewController.swift
//  Hound
//
//  Created by Jonathan Xakellis on 3/16/22.
//  Copyright © 2022 Jonathan Xakellis. All rights reserved.
//

import UIKit

class SettingsAboutViewController: UIViewController {

    // MARK: - Properties
    
    @IBOutlet private weak var version: ScaledUILabel!

    @IBOutlet private weak var build: ScaledUILabel!

    @IBOutlet private weak var copyright: ScaledUILabel!

    // MARK: - Main

    override func viewDidLoad() {
        super.viewDidLoad()
        // TO DO update placeholder text for the about me section
        self.version.text = "Version \(UIApplication.appVersion ?? "nil")"
        self.build.text = "Build \(UIApplication.appBuild)"
        self.copyright.text = "© \(Calendar.current.component(.year, from: Date())) Jonathan Xakellis"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AlertManager.globalPresenter = self
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
