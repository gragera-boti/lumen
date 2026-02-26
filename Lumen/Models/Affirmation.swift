import Foundation
import SwiftData

@Model
final class Affirmation {
    @Attribute(.unique) var id: String = ""
    var locale: String = "en-GB"
    var text: String = ""
    var tone: Tone = Tone.gentle
    var intensity: Intensity = Intensity.low
    var isAbsolute: Bool = false
    var isSensitiveTopic: Bool = false
    var isPremium: Bool = false
    var source: AffirmationSource = AffirmationSource.curated
    var tags: [String] = []
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    /// Optional font style for user-created affirmations (e.g. "serif", "rounded", "handwritten").
    var fontStyle: String?

    var categories: [Category]?

    @Relationship(deleteRule: .cascade, inverse: \Favorite.affirmation)
    var favorite: Favorite?

    @Relationship(deleteRule: .cascade, inverse: \SeenEvent.affirmation)
    var seenEvents: [SeenEvent]?

    @Relationship(deleteRule: .cascade, inverse: \Dislike.affirmation)
    var dislike: Dislike?

    init(
        id: String,
        locale: String = "en-GB",
        text: String,
        tone: Tone = .gentle,
        intensity: Intensity = .low,
        isAbsolute: Bool = false,
        isSensitiveTopic: Bool = false,
        isPremium: Bool = false,
        source: AffirmationSource = .curated,
        tags: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.locale = locale
        self.text = text
        self.tone = tone
        self.intensity = intensity
        self.isAbsolute = isAbsolute
        self.isSensitiveTopic = isSensitiveTopic
        self.isPremium = isPremium
        self.source = source
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.categories = []
        self.seenEvents = []
    }

    var isFavorited: Bool {
        favorite != nil
    }

    var isDisliked: Bool {
        dislike != nil
    }
}
