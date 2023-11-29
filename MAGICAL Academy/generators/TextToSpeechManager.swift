//
//  TextToSpeechManager.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/17/23.
//

import AVFoundation

class TextToSpeechManager {
    private let speechSynthesizer = AVSpeechSynthesizer()

    /// Speaks the given text.
    func speak(text: String, language: String = "en-US") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynthesizer.speak(utterance)
    }

    /// Pauses the current speech.
    func pause() {
        speechSynthesizer.pauseSpeaking(at: .immediate)
    }

    /// Resumes the paused speech.
    func resume() {
        speechSynthesizer.continueSpeaking()
    }

    /// Stops the current speech.
    func stop() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}
