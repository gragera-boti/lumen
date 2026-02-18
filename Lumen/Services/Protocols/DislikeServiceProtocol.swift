import Foundation
import SwiftData

protocol DislikeServiceProtocol: Sendable {
    func dislike(affirmation: Affirmation, reason: String?, modelContext: ModelContext) throws
    func undislike(affirmation: Affirmation, modelContext: ModelContext) throws
}
