//
//  DogsInstantiateRequirementViewController.swift
//  Who Let The Dogs Out
//
//  Created by Jonathan Xakellis on 1/20/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import UIKit

protocol DogsInstantiateRequirementViewControllerDelegate {
    func didAddToList (requirement: Requirement)
}

class DogsInstantiateRequirementViewController: UIViewController {

    var delegate: DogsInstantiateRequirementViewControllerDelegate! = nil
    
    @IBOutlet weak var addToList: UIButton!
    @IBOutlet weak var requirementName: UITextField!
    @IBOutlet weak var requirementDescription: UITextField!
    @IBOutlet weak var requirementInterval: UIDatePicker!
    
    @IBAction func addToList(_ sender: Any) {
        var tempRequirement = Requirement(initDate: Date())
        
        do {
            try tempRequirement.changeLabel(newLabel: requirementName.text)
            try tempRequirement.changeDescription(newDescription: requirementDescription.text)
            try tempRequirement.changeInterval(newInterval: requirementInterval.countDownDuration)
            delegate.didAddToList(requirement: tempRequirement)
            navigationController?.popViewController(animated: true)
        }
        catch DogRequirementError.labelInvalid{
            
            alertForError(message: "Invalid Dog Name")
            
            print("Invalid Requirement Label")
        }
        catch DogRequirementError.descriptionInvalid{
            print("Invalid Requirement Description")
        }
        catch DogRequirementError.intervalInvalid {
            print("Invalid Requirement Time Interval")
        }
        catch {
            print("Invalid Requirement")
        }
        
        
    }
    
    
    func alertForError(message: String){
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requirementName.text = RequirementConstant.defaultLabel
        requirementDescription.text = RequirementConstant.defaultDescription
        requirementInterval.countDownDuration = TimeInterval(RequirementConstant.defaultTimeInterval)
        
        addToList.layer.cornerRadius = 8.0
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