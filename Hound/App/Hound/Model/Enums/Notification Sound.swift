//
//  Notification Sound.swift
//  Hound
//
//  Created by Jonathan Xakellis on 4/6/22.
//  Copyright © 2022 Jonathan Xakellis. All rights reserved.
//

import Foundation

enum NotificationSound: String, CaseIterable {
    // ENUM('Radar','Apex','Beacon','Bulletin','By The Seaside','Chimes','Circuit','Constellation','Cosmic','Crystals','Hillside','Illuminate','Night Owl','Opening','Presto','Reflection','Ripplies','Sencha','Signal','Silk','Stargaze','Twinkle','Waves')
    init?(rawValue: String) {
        for sound in NotificationSound.allCases where sound.rawValue == rawValue {
            self = sound
            return
        }
        
        self = .radar
        return
        
        // case playtime = "Playtime"
        // case radiate = "Radiate"
        // case slowRise = "Slow Rise"
        // case summit = "Summit"
        // case uplift = "Uplift"
    }
    case radar = "Radar"
    case apex = "Apex"
    case beacon = "Beacon"
    case bulletin  = "Bulletin"
    case byTheSeaside = "By The Seaside"
    case chimes  = "Chimes"
    case circuit = "Circuit"
    case constellation = "Constellation"
    case cosmic = "Cosmic"
    case crystals = "Crystals"
    case hillside = "Hillside"
    case illuminate = "Illuminate"
    case nightOwl = "Night Owl"
    case opening = "Opening"
    // case playtime = "Playtime"
    case presto = "Presto"
    // case radiate = "Radiate"
    case reflection = "Reflection"
    case ripples = "Ripples"
    case sencha = "Sencha"
    case signal = "Signal"
    case silk = "Silk"
    // case slowRise = "Slow Rise"
    case stargaze = "Stargaze"
    // case summit = "Summit"
    case twinkle = "Twinkle"
    // case uplift = "Uplift"
    case waves = "Waves"
}