import Foundation
import SwiftData

protocol ContentServiceProtocol: Sendable {
    func loadBundledContentIfNeeded(modelContext: ModelContext) async throws
    func fetchCategories(modelContext: ModelContext, locale: String) throws -> [Category]
    func fetchAffirmation(byId id: String, modelContext: ModelContext) throws -> Affirmation?
}
