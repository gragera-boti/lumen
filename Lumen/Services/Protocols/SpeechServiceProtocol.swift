import Foundation

protocol SpeechServiceProtocol: Sendable {
    func speak(text: String, voice: VoiceSettings) async
    func stop()
    var isSpeaking: Bool { get }
}
