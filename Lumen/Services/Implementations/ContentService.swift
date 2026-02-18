import Foundation
import SwiftData
import OSLog

final class ContentService: ContentServiceProtocol, @unchecked Sendable {
    static let shared = ContentService()
    private let logger = Logger(subsystem: "com.lumen.app", category: "ContentService")

    func loadBundledContentIfNeeded(modelContext: ModelContext) async throws {
        let categoryDescriptor = FetchDescriptor<Category>()
        let existingCount = try modelContext.fetchCount(categoryDescriptor)
        guard existingCount == 0 else { return }

        logger.info("Loading bundled content pack…")
        try loadCategories(modelContext: modelContext)
        try loadAffirmations(modelContext: modelContext)
        try loadDefaultThemes(modelContext: modelContext)
        try modelContext.save()
        logger.info("Bundled content loaded.")
    }

    func fetchCategories(modelContext: ModelContext, locale: String) throws -> [Category] {
        var descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.locale == locale },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        descriptor.fetchLimit = 50
        return try modelContext.fetch(descriptor)
    }

    func fetchAffirmation(byId id: String, modelContext: ModelContext) throws -> Affirmation? {
        var descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Private loaders

    private func loadCategories(modelContext: ModelContext) throws {
        let bundledCategories = try loadJSON([BundledCategory].self, from: "categories_en")
        for bc in bundledCategories {
            let category = Category(
                id: bc.id,
                locale: bc.locale,
                name: bc.name,
                categoryDescription: bc.description,
                icon: bc.icon,
                isPremium: bc.isPremium,
                isSensitive: bc.isSensitive,
                sortOrder: bc.sortOrder,
                updatedAt: bc.updatedAt
            )
            modelContext.insert(category)
        }
    }

    private func loadAffirmations(modelContext: ModelContext) throws {
        let bundledAffirmations = try loadJSON([BundledAffirmation].self, from: "affirmations_en")

        // Build category lookup
        let allCategories = try modelContext.fetch(FetchDescriptor<Category>())
        let categoryMap = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.id, $0) })

        for ba in bundledAffirmations {
            let affirmation = Affirmation(
                id: ba.id,
                locale: ba.locale,
                text: ba.text,
                tone: Tone(rawValue: ba.tone) ?? .gentle,
                intensity: Intensity(rawValue: ba.intensity) ?? .low,
                isAbsolute: ba.absolute,
                isSensitiveTopic: ba.sensitiveTopic,
                isPremium: ba.isPremium,
                source: AffirmationSource(rawValue: ba.source) ?? .curated,
                tags: ba.tags,
                createdAt: ba.createdAt,
                updatedAt: ba.updatedAt
            )
            modelContext.insert(affirmation)

            for catId in ba.categoryIds {
                if let category = categoryMap[catId] {
                    affirmation.categories.append(category)
                }
            }
        }
    }

    private func loadDefaultThemes(modelContext: ModelContext) throws {
        let gradients: [(String, String, [String], Double)] = [
            ("theme_ocean", "Ocean", ["#1B998B", "#3B5998"], 135),
            ("theme_sunset", "Sunset", ["#E8A87C", "#C38D9E"], 45),
            ("theme_lavender", "Lavender", ["#7FBBCA", "#A688B5"], 90),
            ("theme_forest", "Forest", ["#7EC8A0", "#3B5998"], 180),
            ("theme_golden", "Golden Hour", ["#F4D06F", "#E8A87C"], 45),
            ("theme_rose", "Rose", ["#C38D9E", "#7FBBCA"], 135),
        ]

        for (id, name, colors, angle) in gradients {
            let data = GradientData(colors: colors, angleDeg: angle, noise: 0)
            let json = try JSONEncoder().encode(data)
            let theme = AppTheme(
                id: id,
                name: name,
                type: .gradient,
                isPremium: false,
                dataJSON: String(data: json, encoding: .utf8) ?? "{}"
            )
            modelContext.insert(theme)
        }
    }

    private func loadJSON<T: Decodable>(_ type: T.Type, from resource: String) throws -> T {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            throw ContentServiceError.bundleNotFound(resource)
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}

enum ContentServiceError: Error, LocalizedError {
    case bundleNotFound(String)

    var errorDescription: String? {
        switch self {
        case .bundleNotFound(let name): "Content file '\(name).json' not found in bundle."
        }
    }
}

// MARK: - Bundled JSON types

private struct BundledCategory: Decodable {
    let id: String
    let locale: String
    let name: String
    let description: String
    let icon: String
    let isPremium: Bool
    let isSensitive: Bool
    let sortOrder: Int
    let updatedAt: Date
}

private struct BundledAffirmation: Decodable {
    let id: String
    let locale: String
    let text: String
    let tone: String
    let intensity: String
    let absolute: Bool
    let sensitiveTopic: Bool
    let categoryIds: [String]
    let tags: [String]
    let isPremium: Bool
    let source: String
    let createdAt: Date
    let updatedAt: Date
}
