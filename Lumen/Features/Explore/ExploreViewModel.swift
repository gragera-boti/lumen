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
            let allCategories = try contentService.fetchCategories(modelContext: modelContext, locale: "en-GB")

            // Load current preferences to check sensitive content filter
            let prefsDescriptor = FetchDescriptor<UserPreferences>()
            let prefs = try? modelContext.fetch(prefsDescriptor).first
            let includeSensitive = prefs?.includeSensitiveTopics ?? false

            categories = allCategories.filter { category in
                if category.isSensitive && !includeSensitive { return false }
                return true
            }
        } catch {
            logger.error("Failed to load categories: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
