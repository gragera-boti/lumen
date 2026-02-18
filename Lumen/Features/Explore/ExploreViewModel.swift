import Foundation
import SwiftData
import OSLog

@MainActor @Observable
final class ExploreViewModel {
    var categories: [Category] = []
    var isLoading = false
    var errorMessage: String?

    private let contentService: ContentServiceProtocol
    private let logger = Logger(subsystem: "com.lumen.app", category: "Explore")

    init(contentService: ContentServiceProtocol = ContentService.shared) {
        self.contentService = contentService
    }

    func loadCategories(modelContext: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        do {
            categories = try contentService.fetchCategories(modelContext: modelContext, locale: "en-GB")
        } catch {
            logger.error("Failed to load categories: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
