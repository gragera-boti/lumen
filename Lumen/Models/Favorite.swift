import Foundation
import SwiftData

@Model
final class Favorite {
    var affirmation: Affirmation?
    var favoritedAt: Date = Date.now

    init(affirmation: Affirmation, favoritedAt: Date = .now) {
        self.affirmation = affirmation
        self.favoritedAt = favoritedAt
    }
}
