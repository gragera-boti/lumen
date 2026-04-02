import Dependencies
import Foundation
import OSLog
import SwiftData
import SwiftUI

@MainActor @Observable
final class ManageCategoriesViewModel {
    var categories: [Category] = []
    var errorMessage: String?
    
    @ObservationIgnored @Dependency(\.contentService) private var contentService
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "ManageCategories")
    
    func loadCategories(modelContext: ModelContext) async {
        do {
            categories = try contentService.fetchCategories(modelContext: modelContext, locale: "en-GB")
        } catch {
            logger.error("Failed to load categories: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
