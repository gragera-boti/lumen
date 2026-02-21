import Foundation

enum Intensity: String, Codable, CaseIterable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"

    var rawIntensity: Int {
        switch self {
        case .low: 1
        case .medium: 2
        case .high: 3
        }
    }
}
