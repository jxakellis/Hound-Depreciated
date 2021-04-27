//
//  HomeInformationViewController.swift
//  Pupotty
//
//  Created by Jonathan Xakellis on 4/25/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import UIKit

class HomeInformationViewController: UIViewController {
    
    

    //MARK: IB
    
    @IBOutlet weak var purposeBody: CustomLabel!
    
    @IBOutlet weak var howToUseBody: CustomLabel!
    
    @IBAction func willGoBack(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToHomeViewController", sender: self)
    }
    
    
    //MARK: Main
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLabelText()
        
        purposeBody.frame.size = (purposeBody.text?.boundingFrom(font: purposeBody.font, width: purposeBody.frame.width))!
        
        purposeBody.removeConstraint(purposeBody.constraints[0])
        
        howToUseBody.frame.size = (howToUseBody.text?.boundingFrom(font: howToUseBody.font, width: howToUseBody.frame.width))!
        
        howToUseBody.removeConstraint(howToUseBody.constraints[0])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utils.presenter = self
    }
    
    ///Configures the body text to an attributed string, the headers are .semibold and rest is .regular, font size is the one specified in the storyboard
    private func configureLabelText(){
        let howToUseBodyAttributedText = NSMutableAttributedString(string: "Log Reminder:", attributes: [.font:UIFont.systemFont(ofSize: howToUseBody.font.pointSize, weight: .semibold)])
        howToUseBodyAttributedText.append(NSAttributedString(string: "\nIf an alarm sounds and you do it, select \"Did it\". This logs the event and sets the reminder to go off at its next scheduled time. If you complete a reminder early (before its alarm sounds) click on it, select \"Did it\", and Pupotty will handle the rest (more details under \"Skip Reminder:\").\n\n", attributes: [.font:UIFont.systemFont(ofSize: howToUseBody.font.pointSize, weight: .regular)]))
        
        
        howToUseBodyAttributedText.append(NSAttributedString(string: "Snooze Reminder:", attributes: [.font:UIFont.systemFont(ofSize: howToUseBody.font.pointSize, weight: .semibold)]))
        howToUseBodyAttributedText.append(NSAttributedString(string: "\nIf an alarm sounds and you cannot do it right away, select \"Snooze\". This will not log the reminder, but it will sound an alarm again once it is done snoozing. The length of time that it snoozes is configurable in settings.\n\n", attributes: [.font:UIFont.systemFont(ofSize: howToUseBody.font.pointSize, weight: .regular)]))
        
        howToUseBodyAttributedText.append(NSAttributedString(string: "Inactivate Reminder:", attributes: [.font:UIFont.systemFont(ofSize: howToUseBody.font.pointSize, weight: .semibold)]))
        howToUseBodyAttributedText.append(NSAttributedString(string: "\nIf an alarm sounds and you do not want to deal with it, click \"Dismiss\". This won't fully disable the reminder, but it will sit inactive until you click it and select an option. Dismissing reminder will not log it nor will it sound any of its alarms, but it allows you to easily start using it again when you are ready.\n\n", attributes: [.font:UIFont.systemFont(ofSize: howToUseBody.font.pointSize, weight: .regular)]))
        
        
        howToUseBodyAttributedText.append(NSAttributedString(string: "Skip Reminder:", attributes: [.font:UIFont.systemFont(ofSize: howToUseBody.font.pointSize, weight: .semibold)]))
        howToUseBodyAttributedText.append(NSAttributedString(string: "\nIf you complete a reminder early and do not want its alarm to sound, click on it and select \"Did it!\". This will log the reminder and handle its alarm. For a recurring reminder, it will start its countdown over right when the button is selected. For a time of day reminder, it will skip the next alarm. For example, if its 6:50AM and you complete a 7:00AM everyday reminder, then the alarm will sound tomorrow at 7:00AM.\n\n", attributes: [.font:UIFont.systemFont(ofSize: howToUseBody.font.pointSize, weight: .regular)]))
        
        howToUseBodyAttributedText.append(NSAttributedString(string: "Disable Reminder:", attributes: [.font:UIFont.systemFont(ofSize: howToUseBody.font.pointSize, weight: .semibold)]))
        howToUseBodyAttributedText.append(NSAttributedString(string: "\nIf you want to disable a reminder you can do it in two ways, either click on it and select \"Disable\" or go to the Dogs tab and toggle its slider. A disabled reminder's alarms will not sound but can be turned back on by re-enabling the reminder.", attributes: [.font:UIFont.systemFont(ofSize: howToUseBody.font.pointSize, weight: .regular)]))
        howToUseBody.attributedText = howToUseBodyAttributedText
    }
    

}
