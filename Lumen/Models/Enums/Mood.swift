import Foundation

enum Mood: String, Codable, CaseIterable, Identifiable {
    case great
    case good
    case okay
    case low
    case struggling

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .great:      "😊"
        case .good:       "🙂"
        case .okay:       "😐"
        case .low:        "😔"
        case .struggling: "😢"
        }
    }

    var label: String {
        switch self {
        case .great:      "Great"
        case .good:       "Good"
        case .okay:       "Okay"
        case .low:        "Low"
        case .struggling: "Struggling"
        }
    }

    /// Preferred tones for this mood, ordered by priority
    var preferredTones: [Tone] {
        switch self {
        case .great:      [.energetic, .neutral]
        case .good:       [.neutral, .energetic]
        case .okay:       [.neutral, .gentle]
        case .low:        [.gentle, .neutral]
        case .struggling: [.gentle]
        }
    }

    /// Maximum intensity appropriate for this mood
    var maxIntensity: Intensity {
        switch self {
        case .great:      .high
        case .good:       .high
        case .okay:       .medium
        case .low:        .medium
        case .struggling: .low
        }
    }

    /// Whether to exclude absolute statements ("I AM the best")
    var excludeAbsolutes: Bool {
        switch self {
        case .great, .good: false
        case .okay:         false
        case .low:          true
        case .struggling:   true
        }
    }
}
