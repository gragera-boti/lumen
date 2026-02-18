import Foundation
import SwiftData

final class PreferencesService: PreferencesServiceProtocol, @unchecked Sendable {
    static let shared = PreferencesService()

    func getOrCreate(modelContext: ModelContext) throws -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let prefs = UserPreferences()
        modelContext.insert(prefs)
        try modelContext.save()
        return prefs
    }

    func save(modelContext: ModelContext) throws {
        try modelContext.save()
    }
}
