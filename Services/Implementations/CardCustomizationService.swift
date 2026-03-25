import Foundation
import OSLog
import SwiftData

// MARK: - CardCustomizationService

/// Stateless service that manages ``CardCustomization`` persistence via SwiftData.
///
/// Receives a `ModelContext` per call so it carries no mutable state,
/// making it safe to use as a shared singleton across actors.
struct CardCustomizationService: CardCustomizationServiceProtocol {

    /// Shared singleton instance.
    static let shared = CardCustomizationService()

    // MARK: - Read

    func customization(for affirmationId: String, modelContext: ModelContext) throws -> CardCustomization? {
        let descriptor = FetchDescriptor<CardCustomization>(
            predicate: #Predicate { $0.affirmationId == affirmationId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let results = try modelContext.fetch(descriptor)
        return results.first
    }

    func allCustomizations(modelContext: ModelContext) throws -> [CardCustomization] {
        let descriptor = FetchDescriptor<CardCustomization>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func hasCustomization(for affirmationId: String, modelContext: ModelContext) throws -> Bool {
        var descriptor = FetchDescriptor<CardCustomization>(
            predicate: #Predicate { $0.affirmationId == affirmationId }
        )
        descriptor.fetchLimit = 1
        let count = try modelContext.fetchCount(descriptor)
        return count > 0
    }

    // MARK: - Write

    func save(_ customization: CardCustomization, modelContext: ModelContext) throws {
        customization.updatedAt = Date()
        modelContext.insert(customization)
        try modelContext.save()
        Logger.data.debug("Saved card customization for affirmation \(customization.affirmationId, privacy: .private)")
    }

    func delete(for affirmationId: String, modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<CardCustomization>(
            predicate: #Predicate { $0.affirmationId == affirmationId }
        )
        let results = try modelContext.fetch(descriptor)
        for item in results {
            modelContext.delete(item)
        }
        try modelContext.save()
        Logger.data.debug("Deleted card customization for affirmation \(affirmationId, privacy: .private)")
    }
}
