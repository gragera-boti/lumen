import AVFoundation
import Foundation

final class SpeechService: NSObject, SpeechServiceProtocol, @unchecked Sendable {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String, voice: VoiceSettings) async {
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = voice.rate * AVSpeechUtteranceDefaultSpeechRate

        if !voice.voiceId.isEmpty,
           let selectedVoice = AVSpeechSynthesisVoice(identifier: voice.voiceId) {
            utterance.voice = selectedVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: voice.language)
        }

        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
