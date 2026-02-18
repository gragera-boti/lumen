import Foundation
import SwiftData

@Model
final class Dislike {
    var affirmation: Affirmation?
    var dislikedAt: Date
    var reason: String?

    init(affirmation: Affirmation, dislikedAt: Date = .now, reason: String? = nil) {
        self.affirmation = affirmation
        self.dislikedAt = dislikedAt
        self.reason = reason
    }
}
