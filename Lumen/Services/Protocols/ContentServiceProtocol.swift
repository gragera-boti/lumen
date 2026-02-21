import Foundation
import SwiftData

@MainActor
protocol ContentServiceProtocol {
    func loadBundledContentIfNeeded(modelContext: ModelContext) throws
    func fetchCategories(modelContext: ModelContext, locale: String) throws -> [Category]
    func fetchAffirmation(byId id: String, modelContext: ModelContext) throws -> Affirmation?
}
