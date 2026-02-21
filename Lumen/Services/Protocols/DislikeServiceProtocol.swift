import Foundation
import SwiftData

/// Service for managing user dislikes on affirmations.
protocol DislikeServiceProtocol: Sendable {
    /// Mark an affirmation as disliked so it won't appear in future feeds.
    /// - Parameters:
    ///   - affirmation: The affirmation to dislike.
    ///   - reason: An optional user-provided reason for the dislike.
    ///   - modelContext: The SwiftData model context to persist the dislike.
    func dislike(affirmation: Affirmation, reason: String?, modelContext: ModelContext) throws

    /// Remove a dislike from an affirmation, allowing it to appear in feeds again.
    /// - Parameters:
    ///   - affirmation: The affirmation to un-dislike.
    ///   - modelContext: The SwiftData model context to persist the change.
    func undislike(affirmation: Affirmation, modelContext: ModelContext) throws
}
