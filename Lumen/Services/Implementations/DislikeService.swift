import Foundation
import SwiftData

struct DislikeService: DislikeServiceProtocol {
    static let shared = DislikeService()

    func dislike(affirmation: Affirmation, reason: String?, modelContext: ModelContext) throws {
        guard affirmation.dislike == nil else { return }
        let dislike = Dislike(affirmation: affirmation, reason: reason)
        modelContext.insert(dislike)
        try modelContext.save()
    }

    func undislike(affirmation: Affirmation, modelContext: ModelContext) throws {
        if let existing = affirmation.dislike {
            modelContext.delete(existing)
            try modelContext.save()
        }
    }
}
