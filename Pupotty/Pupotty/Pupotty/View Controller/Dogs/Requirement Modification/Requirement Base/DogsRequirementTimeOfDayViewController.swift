//
//  DogsRequirementTimeOfDayViewController.swift
//  Who Let The Dogs Out
//
//  Created by Jonathan Xakellis on 3/28/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import UIKit

protocol DogsRequirementTimeOfDayViewControllerDelegate {
    func willDismissKeyboard()
}

class DogsRequirementTimeOfDayViewController: UIViewController, UIGestureRecognizerDelegate {
    
    //MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    //MARK: IB
    
    @IBOutlet private weak var sunday: ScaledButton!
    @IBOutlet private weak var monday: ScaledButton!
    @IBOutlet private weak var tuesday: ScaledButton!
    @IBOutlet private weak var wednesday: ScaledButton!
    @IBOutlet private weak var thursday: ScaledButton!
    @IBOutlet private weak var friday: ScaledButton!
    @IBOutlet private weak var saturday: ScaledButton!
    
    @IBAction private func toggleWeekdayButton(_ sender: Any) {
        delegate.willDismissKeyboard()
        let senderButton = sender as! ScaledButton
        var targetColor: UIColor!
        
        if senderButton.tintColor == UIColor.systemBlue{
            targetColor = ColorConstant.gray.rawValue
        }
        else {
            targetColor = UIColor.systemBlue
        }
        
        senderButton.isUserInteractionEnabled = false
        UIView.animate(withDuration: AnimationConstant.switchButton.rawValue) {
            senderButton.tintColor = targetColor
        } completion: { (completed) in
            senderButton.isUserInteractionEnabled = true
        }
        
    }
    
    @IBOutlet weak var timeOfDay: UIDatePicker!
    
    @IBAction private func willUpdateTimeOfDay(_ sender: Any) {
        delegate.willDismissKeyboard()
    }
    
    //MARK: Properties
    
    var delegate: DogsRequirementTimeOfDayViewControllerDelegate! = nil
    
    var passedTimeOfDay: Date? = nil
    
    var passedWeekDays: [Int] = [1,2,3,4,5,6,7]
    
    //MARK: Main
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        synchronizeWeekdays()
        
        if passedTimeOfDay != nil {
            timeOfDay.date = passedTimeOfDay!
        }
        else{
            timeOfDay.date = Date.roundDate(targetDate: Date(), roundingInterval: 60.0*5, roundingMethod: .up)
        }
    }
    
    private func synchronizeWeekdays(){
        let dayOfWeekButtons = [self.sunday, self.monday, self.tuesday, self.wednesday, self.thursday, self.friday, self.saturday]
        
        for dayOfWeekButton in dayOfWeekButtons {
            dayOfWeekButton!.tintColor = ColorConstant.gray.rawValue
        }
        
        for dayOfWeek in passedWeekDays{
            switch dayOfWeek {
            case 1:
                sunday.tintColor = .systemBlue
            case 2:
                monday.tintColor = .systemBlue
            case 3:
                tuesday.tintColor = .systemBlue
            case 4:
                wednesday.tintColor = .systemBlue
            case 5:
                thursday.tintColor = .systemBlue
            case 6:
                friday.tintColor = .systemBlue
            case 7:
                saturday.tintColor = .systemBlue
            default:
                print("unknown day of week: \(dayOfWeek)")
            }
        }
    }
    
    ///Converts enabled buttons to an array of day of weeks according to CalendarComponents.weekdays, 1 being sunday and 7 being saturday
    var weekdays: [Int]? {
        var days: [Int] = []
        let dayOfWeekButtons = [self.sunday, self.monday, self.tuesday, self.wednesday, self.thursday, self.friday, self.saturday]
        
        for dayOfWeekIndex in 0..<dayOfWeekButtons.count{
            if dayOfWeekButtons[dayOfWeekIndex]?.tintColor == .systemBlue{
                days.append(dayOfWeekIndex+1)
            }
        }
        
        if days.isEmpty == true {
            return nil
        }
        else {
            return days
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
