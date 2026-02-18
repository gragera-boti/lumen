import Foundation
import SwiftData

@Model
final class Favorite {
    var affirmation: Affirmation?
    var favoritedAt: Date

    init(affirmation: Affirmation, favoritedAt: Date = .now) {
        self.affirmation = affirmation
        self.favoritedAt = favoritedAt
    }
}
