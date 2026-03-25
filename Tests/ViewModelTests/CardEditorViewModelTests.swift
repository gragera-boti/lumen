import Dependencies
import Foundation
import SwiftData
import Testing

@testable import Lumen

// MARK: - Mock Services

private struct MockCardCustomizationService: CardCustomizationServiceProtocol, @unchecked Sendable {
    var savedCustomizations: [CardCustomization] = []
    var shouldThrow: Bool = false

    func customization(for affirmationId: String, modelContext: ModelContext) throws -> CardCustomization? {
        nil
    }

    func allCustomizations(modelContext: ModelContext) throws -> [CardCustomization] {
        []
    }

    func save(_ customization: CardCustomization, modelContext: ModelContext) throws {
        if shouldThrow { throw TestError.saveFailed }
        modelContext.insert(customization)
        try modelContext.save()
    }

    func delete(for affirmationId: String, modelContext: ModelContext) throws {
        if shouldThrow { throw TestError.deleteFailed }
        let descriptor = FetchDescriptor<CardCustomization>(
            predicate: #Predicate { $0.affirmationId == affirmationId }
        )
        let results = try modelContext.fetch(descriptor)
        for item in results { modelContext.delete(item) }
        try modelContext.save()
    }

    func hasCustomization(for affirmationId: String, modelContext: ModelContext) throws -> Bool {
        false
    }
}

private struct MockBackgroundGenerator: BackgroundGeneratorProtocol {
    func generate(request: BackgroundRequest) async throws -> GeneratedBackground {
        throw BackgroundGeneratorError.cancelled
    }

    func cancelGeneration() async {}
}

private enum TestError: Error {
    case saveFailed
    case deleteFailed
}

// MARK: - Tests

@Suite("CardEditorViewModel")
struct CardEditorViewModelTests {

    private func makeModelContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Affirmation.self,
            CardCustomization.self,
            configurations: config
        )
        return ModelContext(container)
    }

    private func makeAffirmation(source: AffirmationSource = .curated, fontStyle: String? = nil) -> Affirmation {
        let aff = Affirmation(
            id: "test_\(UUID().uuidString.prefix(8))",
            text: "I am confident and strong",
            tone: .gentle,
            intensity: .low,
            source: source
        )
        aff.fontStyle = fontStyle
        return aff
    }

    @MainActor private func makeViewModel(
        affirmation: Affirmation,
        existingCustomization: CardCustomization? = nil
    ) -> CardEditorViewModel {
        withDependencies {
            $0.cardCustomizationService = MockCardCustomizationService()
            $0.backgroundGenerator = MockBackgroundGenerator()
        } operation: {
            CardEditorViewModel(
                affirmation: affirmation,
                existingCustomization: existingCustomization
            )
        }
    }

    @Test("Initial state from nil customization uses defaults")
    @MainActor
    func initialStateFromNilCustomization() {
        let affirmation = makeAffirmation()
        let viewModel = makeViewModel(affirmation: affirmation)

        #expect(viewModel.customText == affirmation.text)
        #expect(viewModel.selectedFontStyle == nil)
        #expect(!viewModel.hasChanges)
    }

    @Test("Initial state from existing customization")
    @MainActor
    func initialStateFromExistingCustomization() {
        let affirmation = makeAffirmation()
        let customization = CardCustomization(
            affirmationId: affirmation.id,
            backgroundStyle: GeneratorStyle.cosmos.rawValue,
            colorPalette: ColorPalette.cherry.rawValue,
            backgroundSeed: 42,
            fontStyleOverride: AffirmationFontStyle.cormorant.rawValue,
            customText: "Custom text"
        )

        let viewModel = makeViewModel(affirmation: affirmation, existingCustomization: customization)

        #expect(viewModel.selectedStyle == .cosmos)
        #expect(viewModel.selectedPalette == .cherry)
        #expect(viewModel.selectedFontStyle == .cormorant)
        #expect(viewModel.customText == "Custom text")
        #expect(viewModel.backgroundSeed == 42)
        #expect(!viewModel.hasChanges)
    }

    @Test("canEditText is true for user source, false for curated")
    @MainActor
    func canEditTextBySource() {
        let userAff = makeAffirmation(source: .user)
        let curatedAff = makeAffirmation(source: .curated)

        let userVM = makeViewModel(affirmation: userAff)
        let curatedVM = makeViewModel(affirmation: curatedAff)

        #expect(userVM.canEditText == true)
        #expect(curatedVM.canEditText == false)
    }

    @Test("hasChanges detects modifications")
    @MainActor
    func hasChangesDetection() {
        let affirmation = makeAffirmation()
        let viewModel = makeViewModel(affirmation: affirmation)

        #expect(!viewModel.hasChanges)

        viewModel.selectedStyle = .cosmos
        #expect(viewModel.hasChanges)
    }

    @Test("save creates CardCustomization in context")
    @MainActor
    func saveCreatesCustomization() throws {
        let modelContext = try makeModelContext()
        let affirmation = makeAffirmation(source: .user)
        modelContext.insert(affirmation)
        try modelContext.save()

        let viewModel = makeViewModel(affirmation: affirmation)

        viewModel.selectedStyle = .watercolor
        viewModel.selectedPalette = .sakura
        viewModel.selectedFontStyle = .dancing

        try viewModel.save(modelContext: modelContext)

        let affId = affirmation.id
        let descriptor = FetchDescriptor<CardCustomization>(
            predicate: #Predicate { $0.affirmationId == affId }
        )
        let results = try modelContext.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results.first?.backgroundStyle == GeneratorStyle.watercolor.rawValue)
        #expect(results.first?.colorPalette == ColorPalette.sakura.rawValue)
        #expect(results.first?.fontStyleOverride == AffirmationFontStyle.dancing.rawValue)
    }

    @Test("resetToDefaults deletes customization")
    @MainActor
    func resetToDefaultsDeletesCustomization() throws {
        let modelContext = try makeModelContext()
        let affirmation = makeAffirmation()
        modelContext.insert(affirmation)

        let customization = CardCustomization(
            affirmationId: affirmation.id,
            backgroundStyle: GeneratorStyle.cosmos.rawValue
        )
        modelContext.insert(customization)
        try modelContext.save()

        let viewModel = makeViewModel(affirmation: affirmation, existingCustomization: customization)

        try viewModel.resetToDefaults(modelContext: modelContext)

        let affId = affirmation.id
        let descriptor = FetchDescriptor<CardCustomization>(
            predicate: #Predicate { $0.affirmationId == affId }
        )
        let results = try modelContext.fetch(descriptor)
        #expect(results.isEmpty)
    }

    @Test("randomizeSeed changes the seed value")
    @MainActor
    func randomizeSeedChangesSeed() {
        let affirmation = makeAffirmation()
        let viewModel = makeViewModel(affirmation: affirmation)

        let originalSeed = viewModel.backgroundSeed
        var changed = false
        for _ in 0..<10 {
            viewModel.randomizeSeed()
            if viewModel.backgroundSeed != originalSeed {
                changed = true
                break
            }
        }
        #expect(changed)
    }
}
