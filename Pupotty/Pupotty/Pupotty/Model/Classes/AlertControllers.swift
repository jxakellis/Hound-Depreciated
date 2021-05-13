//
//  CustomClasses.swift
//  Pupotty
//
//  Created by Jonathan Xakellis on 4/15/21.
//  Copyright © 2021 Jonathan Xakellis. All rights reserved.
//

import MediaPlayer
import UIKit
import AudioToolbox
import AVFoundation

class GeneralAlertController: UIAlertController {
    override func viewDidDisappear(_ animated: Bool) {
        AlertPresenter.shared.viewDidComplete()
    }
}

class AlarmAlertController: GeneralAlertController {
    
    private var audioPlayer: AVAudioPlayer!
    
    
    
    private func loadAlarmSound(){
        
        let path = Bundle.main.path(forResource: "radar.wav", ofType: nil)!
        let url = URL(fileURLWithPath: path)

        do {
            //create your audioPlayer in your parent class as a property
            try! AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
            DispatchQueue.main.async {
               // MPVolumeView.setVolume(1.0)
            }
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.numberOfLoops = .max
            
        } catch {
            print("couldn't load file for loadAlarmSound")
        }
    }
    
    private var shouldVibrate = true
    private func loopVibrate(){
        if shouldVibrate == true {
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    self.loopVibrate()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global().async{
            self.loadAlarmSound()
            self.loopVibrate()
            self.audioPlayer.play()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global().async{
            self.audioPlayer.stop()
            self.shouldVibrate = false
        }
    }
}

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
