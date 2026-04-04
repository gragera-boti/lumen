import Dependencies
import Foundation
import OSLog
import SwiftData
import SwiftUI

@MainActor @Observable
final class ManageCategoriesViewModel {
    var categories: [Category] = []
    var isPremium = false
    var errorMessage: String?
    
    @ObservationIgnored @Dependency(\.contentService) private var contentService
    @ObservationIgnored @Dependency(\.entitlementService) private var entitlementService
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "ManageCategories")
    
    func loadCategories(modelContext: ModelContext) async {
        isPremium = await entitlementService.isPremium()
        do {
            categories = try contentService.fetchCategories(modelContext: modelContext, locale: "en-GB")
        } catch {
            logger.error("Failed to load categories: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
