import Foundation
import SwiftData

protocol PreferencesServiceProtocol: Sendable {
    func getOrCreate(modelContext: ModelContext) throws -> UserPreferences
    func save(modelContext: ModelContext) throws
}
