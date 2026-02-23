import Foundation
import SwiftData

/// Service for loading and querying bundled content (categories, affirmations, themes).
@MainActor
protocol ContentServiceProtocol: Sendable {
    /// Load all bundled JSON content into SwiftData on first launch.
    /// No-op if categories already exist in the store.
    /// - Parameter modelContext: The SwiftData model context to insert content into.
    func loadBundledContentIfNeeded(modelContext: ModelContext) throws

    /// Fetch all categories for a given locale, sorted by display order.
    /// - Parameters:
    ///   - modelContext: The SwiftData model context to query.
    ///   - locale: The locale identifier (e.g. `"en"`) to filter categories by.
    /// - Returns: An array of matching ``Category`` objects.
    func fetchCategories(modelContext: ModelContext, locale: String) throws -> [Category]

    /// Fetch a single affirmation by its unique identifier.
    /// - Parameters:
    ///   - id: The affirmation's unique identifier.
    ///   - modelContext: The SwiftData model context to query.
    /// - Returns: The matching ``Affirmation``, or `nil` if not found.
    func fetchAffirmation(byId id: String, modelContext: ModelContext) throws -> Affirmation?
}
