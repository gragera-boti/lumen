import Foundation
import SwiftData
import Testing

@testable import Lumen

// MARK: - CardCustomizationServiceTests

@Suite("CardCustomizationService")
struct CardCustomizationServiceTests {

    private let service = CardCustomizationService()

    /// Creates an in-memory `ModelContext` for isolated test execution.
    private func makeContext() throws -> ModelContext {
        let schema = Schema([CardCustomization.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    // MARK: - Tests

    @Test("Save and fetch a customization")
    func saveAndFetch() throws {
        let context = try makeContext()
        let customization = CardCustomization(
            affirmationId: "aff-001",
            backgroundStyle: "gradient",
            colorPalette: "sunset",
            backgroundSeed: 42,
            fontStyleOverride: "serif"
        )

        try service.save(customization, modelContext: context)

        let fetched = try service.customization(for: "aff-001", modelContext: context)
        let result = try #require(fetched)
        #expect(result.affirmationId == "aff-001")
        #expect(result.backgroundStyle == "gradient")
        #expect(result.colorPalette == "sunset")
        #expect(result.backgroundSeed == 42)
        #expect(result.fontStyleOverride == "serif")
        #expect(result.customText == nil)
    }

    @Test("Update existing customization")
    func updateExisting() throws {
        let context = try makeContext()
        let customization = CardCustomization(
            affirmationId: "aff-002",
            backgroundStyle: "solid"
        )
        try service.save(customization, modelContext: context)

        // Mutate and re-save
        customization.backgroundStyle = "mesh"
        customization.fontStyleOverride = "mono"
        try service.save(customization, modelContext: context)

        let fetched = try #require(try service.customization(for: "aff-002", modelContext: context))
        #expect(fetched.backgroundStyle == "mesh")
        #expect(fetched.fontStyleOverride == "mono")
    }

    @Test("Delete customization")
    func deleteCustomization() throws {
        let context = try makeContext()
        let customization = CardCustomization(affirmationId: "aff-003")
        try service.save(customization, modelContext: context)

        try service.delete(for: "aff-003", modelContext: context)

        let fetched = try service.customization(for: "aff-003", modelContext: context)
        #expect(fetched == nil)
    }

    @Test("hasCustomization returns correct values")
    func hasCustomization() throws {
        let context = try makeContext()

        #expect(try service.hasCustomization(for: "aff-004", modelContext: context) == false)

        let customization = CardCustomization(affirmationId: "aff-004")
        try service.save(customization, modelContext: context)

        #expect(try service.hasCustomization(for: "aff-004", modelContext: context) == true)
    }

    @Test("Fetching nonexistent returns nil")
    func fetchNonexistent() throws {
        let context = try makeContext()
        let result = try service.customization(for: "does-not-exist", modelContext: context)
        #expect(result == nil)
    }

    @Test("allCustomizations returns all saved")
    func allCustomizations() throws {
        let context = try makeContext()

        let c1 = CardCustomization(affirmationId: "aff-100")
        let c2 = CardCustomization(affirmationId: "aff-101")
        let c3 = CardCustomization(affirmationId: "aff-102")
        try service.save(c1, modelContext: context)
        try service.save(c2, modelContext: context)
        try service.save(c3, modelContext: context)

        let all = try service.allCustomizations(modelContext: context)
        #expect(all.count == 3)

        let ids = Set(all.map(\.affirmationId))
        #expect(ids == Set(["aff-100", "aff-101", "aff-102"]))
    }
}
