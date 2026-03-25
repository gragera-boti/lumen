import Foundation

enum Tone: String, Codable, CaseIterable, Identifiable {
    case gentle = "GENTLE"
    case neutral = "NEUTRAL"
    case energetic = "ENERGETIC"
    case spiritual = "SPIRITUAL"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gentle: "Gentle"
        case .neutral: "Neutral"
        case .energetic: "Energetic"
        case .spiritual: "Spiritual"
        }
    }

    var description: String {
        switch self {
        case .gentle: "Kind and self-compassionate"
        case .neutral: "Balanced and grounded"
        case .energetic: "Motivating and action-oriented"
        case .spiritual: "Purpose and meaning"
        }
    }

    var iconName: String {
        switch self {
        case .gentle: "leaf.fill"
        case .neutral: "circle.fill"
        case .energetic: "bolt.fill"
        case .spiritual: "sun.max.fill"
        }
    }
}
