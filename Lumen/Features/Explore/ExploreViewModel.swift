import Foundation
import SwiftData
import OSLog

@MainActor @Observable
final class ExploreViewModel {
    var categories: [Category] = []
    var isPremium = false
    var isLoading = false
    var errorMessage: String?

    private let contentService: ContentServiceProtocol
    private let entitlementService: EntitlementServiceProtocol
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "Explore")

    init(
        contentService: ContentServiceProtocol = ContentService.shared,
        entitlementService: EntitlementServiceProtocol = EntitlementService.shared
    ) {
        self.contentService = contentService
        self.entitlementService = entitlementService
    }

    func loadData(modelContext: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        isPremium = await entitlementService.isPremium()

        do {
            categories = try contentService.fetchCategories(modelContext: modelContext, locale: "en-GB")
        } catch {
            logger.error("Failed to load categories: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
