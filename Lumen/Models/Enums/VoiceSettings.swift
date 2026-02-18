import Foundation

struct VoiceSettings: Codable, Equatable {
    var language: String
    var voiceId: String
    var rate: Float

    static let defaults = VoiceSettings(
        language: "en-GB",
        voiceId: "",
        rate: 1.0
    )
}
