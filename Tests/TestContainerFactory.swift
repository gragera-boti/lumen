import Foundation
import SwiftData
@testable import Lumen

@MainActor
enum TestContainerFactory {
    private static let lock = NSLock()

    static func makeContainer() throws -> ModelContainer {
        lock.lock()
        defer { lock.unlock() }

        let schema = LumenApp.appSchema
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        let config = ModelConfiguration(
            url: url,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
