//
//  AudioPlayerDelegate.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/11/23.
//

import AVFoundation

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Handle the audio player finishing playback here
    }
}

