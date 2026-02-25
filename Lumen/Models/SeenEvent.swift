import Foundation
import SwiftData

@Model
final class SeenEvent {
    var affirmation: Affirmation?
    var seenAt: Date = Date.now
    var source: SeenSource = SeenSource.feed

    init(affirmation: Affirmation, seenAt: Date = .now, source: SeenSource = .feed) {
        self.affirmation = affirmation
        self.seenAt = seenAt
        self.source = source
    }
}
