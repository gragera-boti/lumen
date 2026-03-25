import Foundation
import SwiftData

// MARK: - CardCustomizationServiceProtocol

/// Defines the contract for managing per-affirmation card visual customizations.
///
/// All methods receive a `ModelContext` per call, keeping the service stateless
/// and compatible with SwiftData's concurrency model.
protocol CardCustomizationServiceProtocol: Sendable {

    /// Fetches the customization for a specific affirmation, if one exists.
    ///
    /// - Parameters:
    ///   - affirmationId: The unique identifier of the affirmation.
    ///   - modelContext: The `ModelContext` to query against.
    /// - Returns: The matching ``CardCustomization``, or `nil` if none exists.
    /// - Throws: If the fetch operation fails.
    func customization(for affirmationId: String, modelContext: ModelContext) throws -> CardCustomization?

    /// Fetches all saved customizations.
    ///
    /// Useful for sync, export, or bulk operations.
    ///
    /// - Parameter modelContext: The `ModelContext` to query against.
    /// - Returns: An array of all ``CardCustomization`` records.
    /// - Throws: If the fetch operation fails.
    func allCustomizations(modelContext: ModelContext) throws -> [CardCustomization]

    /// Saves or updates a customization.
    ///
    /// If the customization is new it will be inserted; if it already exists
    /// in the context the changes are persisted on the next save.
    ///
    /// - Parameters:
    ///   - customization: The ``CardCustomization`` to persist.
    ///   - modelContext: The `ModelContext` to save into.
    /// - Throws: If the save operation fails.
    func save(_ customization: CardCustomization, modelContext: ModelContext) throws

    /// Deletes the customization for a given affirmation, reverting it to defaults.
    ///
    /// If no customization exists for the given ID, this method does nothing.
    ///
    /// - Parameters:
    ///   - affirmationId: The unique identifier of the affirmation.
    ///   - modelContext: The `ModelContext` to delete from.
    /// - Throws: If the delete operation fails.
    func delete(for affirmationId: String, modelContext: ModelContext) throws

    /// Checks whether a customization exists for the given affirmation.
    ///
    /// - Parameters:
    ///   - affirmationId: The unique identifier of the affirmation.
    ///   - modelContext: The `ModelContext` to query against.
    /// - Returns: `true` if a customization record exists, `false` otherwise.
    /// - Throws: If the fetch operation fails.
    func hasCustomization(for affirmationId: String, modelContext: ModelContext) throws -> Bool
}
