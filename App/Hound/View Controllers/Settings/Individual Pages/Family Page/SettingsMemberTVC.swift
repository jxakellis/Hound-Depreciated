//
//  SettingsFamilyMemberTableViewCell.swift
//  Hound
//
//  Created by Jonathan Xakellis on 4/5/22.
//  Copyright © 2022 Jonathan Xakellis. All rights reserved.
//

import UIKit

final class SettingsFamilyMemberTableViewCell: UITableViewCell {

    // MARK: - IB
    
    @IBOutlet private weak var fullNameLabel: ScaledUILabel!
    
    @IBOutlet private weak var rightChevronImageView: UIImageView!
    @IBOutlet private weak var rightChevronLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var rightChevronAspectRatio: NSLayoutConstraint!
    
    // MARK: - Properties
    
    var userId: String!
    
    // MARK: - Main
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    // MARK: - Functions
    
    func setup(forDisplayFullName displayFullName: String, userId: String) {
        self.userId = userId
        
        fullNameLabel.text = displayFullName
        
        let isFamilyHead = FamilyConfiguration.isFamilyHead
        // if the user is not the family head, that means the cell should not be selectable nor should we show the chevron that indicates selectability
        isUserInteractionEnabled = isFamilyHead
        rightChevronImageView.isHidden = !isFamilyHead
        
        rightChevronLeadingConstraint.constant = isFamilyHead ? 10.0 : 0.0
        
        if isFamilyHead == false {
            
            if let rightChevronAspectRatio = rightChevronAspectRatio {
                // upon cell reload, the rightChevronAspectRatio can be nil if deactived already
                NSLayoutConstraint.deactivate([rightChevronAspectRatio])
            }
           
            NSLayoutConstraint.activate([ rightChevronImageView.widthAnchor.constraint(equalToConstant: 0.0)])
        }
    }

}