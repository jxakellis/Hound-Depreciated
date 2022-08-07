//
//  SettingsSubscriptionTierTableViewCell.swift
//  Hound
//
//  Created by Jonathan Xakellis on 6/15/22.
//  Copyright © 2022 Jonathan Xakellis. All rights reserved.
//

import UIKit
import StoreKit

final class SettingsSubscriptionTierTableViewCell: UITableViewCell {
    
    // MARK: - IB
    
    @IBOutlet private weak var subscriptionTierTitleLabel: ScaledUILabel!
    @IBOutlet private weak var subscriptionTierDescriptionLabel: ScaledUILabel!
    
    @IBOutlet weak var subscriptionTierPricingTitleLabel: ScaledUILabel!
    @IBOutlet private weak var subscriptionTierPricingDescriptionLabel: ScaledUILabel!
    
    // MARK: - Properties
    
    var product: SKProduct?
    var inAppPurchaseProduct: InAppPurchaseProduct = InAppPurchaseProduct.default
    
    // MARK: - Main

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - Functions
    
    func setup(forProduct product: SKProduct?) {
        
        self.product = product
        
        let activeFamilySubscriptionProduct = FamilyConfiguration.activeFamilySubscription.product
        
        guard let product: SKProduct = product, product.subscriptionPeriod != nil else {
            self.inAppPurchaseProduct = .default
            
            changeCellColors(isProductActiveSubscription: activeFamilySubscriptionProduct == InAppPurchaseProduct.default)
            subscriptionTierTitleLabel.text = InAppPurchaseProduct.localizedTitleExpanded(forInAppPurchaseProduct: InAppPurchaseProduct.default)
            subscriptionTierDescriptionLabel.text =  InAppPurchaseProduct.localizedDescriptionExpanded(forInAppPurchaseProduct: InAppPurchaseProduct.default)
            subscriptionTierPricingDescriptionLabel.text = "Completely and always free! You get to benefit from the same features as paid subscribers. The only difference is family member and dog limits."
            return
        }
        
        self.inAppPurchaseProduct = InAppPurchaseProduct(rawValue: product.productIdentifier) ?? .unknown
        
        changeCellColors(isProductActiveSubscription: inAppPurchaseProduct == activeFamilySubscriptionProduct)
        
        if inAppPurchaseProduct != .unknown {
            // if we know what product it is, then highlight the cell if its product is the current, active subscription
            subscriptionTierTitleLabel.text = InAppPurchaseProduct.localizedTitleExpanded(forInAppPurchaseProduct: inAppPurchaseProduct)
            subscriptionTierDescriptionLabel.text = InAppPurchaseProduct.localizedDescriptionExpanded(forInAppPurchaseProduct: inAppPurchaseProduct)
        }
        else {
            subscriptionTierTitleLabel.text = product.localizedTitle
            subscriptionTierTitleLabel.text = product.localizedDescription
        }
        
        // now we have to determine what the pricing is like
        // first get the properties
        let subscriptionPriceWithSymbol = "\(product.priceLocale.currencySymbol ?? "")\(product.price)"
        let subscriptionPeriod = convertSubscriptionPeriodUnits(forUnit: product.subscriptionPeriod!.unit, forNumberOfUnits: product.subscriptionPeriod!.numberOfUnits, isFreeTrialText: false)
        
        // no free trial
        if product.introductoryPrice == nil || product.introductoryPrice!.paymentMode != .freeTrial {
            subscriptionTierPricingDescriptionLabel.text = "Enjoy all \(product.localizedTitle) has to offer for \(subscriptionPriceWithSymbol) per \(subscriptionPeriod)"
        }
        // tier offers a free trial
        else {
            let freeTrialSubscriptionPeriod = convertSubscriptionPeriodUnits(forUnit: product.introductoryPrice!.subscriptionPeriod.unit, forNumberOfUnits: product.introductoryPrice!.subscriptionPeriod.numberOfUnits, isFreeTrialText: true)
            
            subscriptionTierPricingDescriptionLabel.text = "Begin with a free \(freeTrialSubscriptionPeriod) trial then continue your \(product.localizedTitle) experience for \(subscriptionPriceWithSymbol) per \(subscriptionPeriod)"
        }
    }
    
    /// If the cell has a product identifier that is the same as the family's active subscription, then we change the colors of the cell to make it highlighted
    private func changeCellColors(isProductActiveSubscription: Bool) {
        self.backgroundColor = isProductActiveSubscription
        ? .systemBlue
        : .systemBackground
        subscriptionTierTitleLabel.textColor = isProductActiveSubscription
        ? .white
        : .label
        subscriptionTierDescriptionLabel.textColor = isProductActiveSubscription
        ? .white
        : .secondaryLabel
        
        subscriptionTierPricingTitleLabel.textColor = isProductActiveSubscription
        ? .white
        : .label
        subscriptionTierPricingDescriptionLabel.textColor = isProductActiveSubscription
        ? .white
        : .secondaryLabel
    }
    
    /// Converts from units (time period: day, week, month, year) and numberOfUnits (duration: 1, 2, 3...) to the correct string. For example: unit = 2 & numerOfUnits = 3 -> "three (3) months"; unit = 1 & numerOfUnits = 2 -> "two (2) weeks"
    private func convertSubscriptionPeriodUnits(forUnit unit: SKProduct.PeriodUnit, forNumberOfUnits numberOfUnits: Int, isFreeTrialText: Bool) -> String {
        var string = ""
        
        // if the numberOfUnits isn't equal to 1, then we append its value. This is so we get the returns of "month", "two (2) months", "three (3) months"
        
        if numberOfUnits != 1 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .spellOut
            let numberOfUnitsValueSpelledOut = formatter.string(from: numberOfUnits as NSNumber)
            
            // make sure to add an extra space onto the back. we can remove that at the end.
            if numberOfUnitsValueSpelledOut != nil {
                // NO TEXT FOR ONE (1)
                // "two (2) "
                // "three (3) "
                // ...
                string.append("\(numberOfUnitsValueSpelledOut!) (\(numberOfUnits)) ")
            }
            else {
                // NO TEXT FOR 1
                // "2 "
                // "3 "
                // ...
                string.append("\(numberOfUnits) ")
            }
        }
        
        // At this point, depending on our numberOfUnits.rawValue, we have:
        // " "
        // "two (2) "
        // "three (3) "
        
        // Now we need to append the correct time period
        
        switch unit.rawValue {
        case 0:
            string.append("day")
        case 1:
            string.append("week")
        case 2:
            string.append("month")
        case 3:
            string.append("year")
        default:
            string.append(VisualConstant.TextConstant.unknownText)
        }
        
        // If our unit is plural (e.g. 2 days, 3 days), then we need to append that "s" to go from day -> days. Additionally we check to make sure our unit is within a valid range, otherwise we don't want to append "s" to "unknown⚠️"
        if isFreeTrialText == false && numberOfUnits != 1 && 0...3 ~= unit.rawValue {
            string.append("s")
        }
        
        return string
        
    }

}