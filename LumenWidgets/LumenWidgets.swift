import SwiftUI
import WidgetKit

// MARK: - Widget Data

struct WidgetAffirmation: Codable {
    let id: String
    let text: String
    let gradientColors: [String]
    let backgroundImageFilename: String?
    let textColor: String?
    let updatedAt: Date
}

struct WidgetSnapshotList: Codable {
    let entries: [WidgetAffirmation]
    let updatedAt: Date
}

// MARK: - Timeline Provider

struct LumenTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> LumenEntry {
        if let data = loadEntries().first {
             return LumenEntry(
                 date: .now,
                 affirmationText: data.text,
                 gradientColors: data.gradientColors,
                 backgroundImageFilename: data.backgroundImageFilename,
                 textColor: data.textColor
             )
        }
        return LumenEntry(
            date: .now,
            affirmationText: "I can take one small step today.",
            gradientColors: ["#7FBBCA", "#A688B5"],
            backgroundImageFilename: nil,
            textColor: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LumenEntry) -> Void) {
        if let data = loadEntries().first {
            let entry = LumenEntry(
                date: Date(),
                affirmationText: data.text,
                gradientColors: data.gradientColors,
                backgroundImageFilename: data.backgroundImageFilename,
                textColor: data.textColor
            )
            completion(entry)
        } else {
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LumenEntry>) -> Void) {
        let entries = loadEntries()
        guard !entries.isEmpty else {
            let entry = placeholder(in: context)
            completion(Timeline(entries: [entry], policy: .after(Date().adding(hours: 4))))
            return
        }

        var timelineEntries: [LumenEntry] = []
        let now = Date()
        for i in 0..<min(entries.count, 6) {
            let entryDate = now.adding(hours: i * 4)
            let data = entries[i]
            timelineEntries.append(LumenEntry(
                date: entryDate,
                affirmationText: data.text,
                gradientColors: data.gradientColors,
                backgroundImageFilename: data.backgroundImageFilename,
                textColor: data.textColor
            ))
        }

        let timeline = Timeline(entries: timelineEntries, policy: .after(now.adding(hours: min(entries.count, 6) * 4)))
        completion(timeline)
    }

    private func loadEntries() -> [WidgetAffirmation] {
        guard
            let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen"
            )
        else { return [] }

        let fileURL = containerURL.appendingPathComponent("widget_snapshot.json")
        guard let data = try? Data(contentsOf: fileURL),
            let snapshotList = try? JSONDecoder().decode(WidgetSnapshotList.self, from: data)
        else {
            return []
        }
        return snapshotList.entries
    }
}

// MARK: - Timeline Entry

struct LumenEntry: TimelineEntry {
    let date: Date
    let affirmationText: String
    let gradientColors: [String]
    let backgroundImageFilename: String?
    let textColor: String?
}

// MARK: - Widget Views

struct LumenWidgetEntryView: View {
    var entry: LumenEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack {
            Spacer()

            let fg = entry.textColor.map { Color(hex: $0) } ?? Color.white
            Text(entry.affirmationText)
                .font(textFont)
                .foregroundStyle(fg)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                .minimumScaleFactor(0.7)

            Spacer()

            if family != .systemSmall {
                Text("Lumen")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .containerBackground(for: .widget) {
            ZStack {
                if let filename = entry.backgroundImageFilename,
                   let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen"),
                   let uiImage = UIImage(contentsOfFile: containerURL.appendingPathComponent(filename).path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: entry.gradientColors.map { Color(hex: $0) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                // Readability overlay
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0),
                        .init(color: .black.opacity(0.3), location: 0.6),
                        .init(color: .black.opacity(0.2), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var textFont: Font {
        switch family {
        case .systemSmall:
            .system(.callout, design: .serif, weight: .medium)
        case .systemMedium:
            .system(.body, design: .serif, weight: .medium)
        case .systemLarge:
            .system(.title3, design: .serif, weight: .medium)
        default:
            .system(.body, design: .serif, weight: .medium)
        }
    }
}

// MARK: - Widget Configuration

struct LumenWidget: Widget {
    let kind: String = "LumenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LumenTimelineProvider()) { entry in
            LumenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Affirmation")
        .description("A gentle reminder throughout your day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Favorites Widget

struct FavoritesTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FavoritesEntry {
        if let fav = loadFavorites().first {
             return FavoritesEntry(
                 date: .now,
                 affirmationText: fav.text,
                 gradientColors: fav.gradientColors,
                 backgroundImageFilename: fav.backgroundImageFilename,
                 textColor: fav.textColor
             )
        }
        return .empty
    }

    func getSnapshot(in context: Context, completion: @escaping (FavoritesEntry) -> Void) {
        let entry = loadRandomEntry() ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoritesEntry>) -> Void) {
        let favorites = loadFavorites()
        guard !favorites.isEmpty else {
            let timeline = Timeline(entries: [FavoritesEntry.empty], policy: .after(Date().adding(hours: 1)))
            completion(timeline)
            return
        }

        // Create entries that rotate every 30 minutes
        var entries: [FavoritesEntry] = []
        let now = Date()
        for i in 0..<min(favorites.count, 48) {
            let entryDate = now.adding(minutes: i * 30)
            let fav = favorites[i % favorites.count]
            entries.append(
                FavoritesEntry(
                    date: entryDate,
                    affirmationText: fav.text,
                    gradientColors: fav.gradientColors,
                    backgroundImageFilename: fav.backgroundImageFilename,
                    textColor: fav.textColor
                )
            )
        }

        let timeline = Timeline(entries: entries, policy: .after(now.adding(hours: 24)))
        completion(timeline)
    }

    private func loadFavorites() -> [FavoriteWidgetEntry] {
        guard
            let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen"
            )
        else { return [] }

        let fileURL = containerURL.appendingPathComponent("favorites_widget.json")
        guard let data = try? Data(contentsOf: fileURL),
            let snapshot = try? JSONDecoder().decode(FavoritesWidgetSnapshot.self, from: data)
        else {
            return []
        }
        return snapshot.favorites.shuffled()
    }

    private func loadRandomEntry() -> FavoritesEntry? {
        guard let fav = loadFavorites().randomElement() else { return nil }
        return FavoritesEntry(
            date: .now,
            affirmationText: fav.text,
            gradientColors: fav.gradientColors,
            backgroundImageFilename: fav.backgroundImageFilename,
            textColor: fav.textColor
        )
    }
}

struct FavoritesEntry: TimelineEntry {
    let date: Date
    let affirmationText: String
    let gradientColors: [String]
    let backgroundImageFilename: String?
    let textColor: String?
    var isEmpty: Bool = false

    static var empty: FavoritesEntry {
        FavoritesEntry(
            date: .now,
            affirmationText: "",
            gradientColors: ["#A688B5", "#E8837C"],
            backgroundImageFilename: nil,
            textColor: nil,
            isEmpty: true
        )
    }
}

struct FavoritesWidgetEntryView: View {
    var entry: FavoritesEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack {
            if entry.isEmpty {
                Spacer()
                Image(systemName: "heart")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
                Text("No favorites yet")
                    .font(.system(.caption, design: .serif, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                if family != .systemSmall {
                    Text("Open Lumen to add some")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                Spacer()

                let fg = entry.textColor.map { Color(hex: $0) } ?? Color.white
                Text(entry.affirmationText)
                    .font(textFont)
                    .foregroundStyle(fg)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                    .minimumScaleFactor(0.7)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                    if family != .systemSmall {
                        Text("Favorites")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.white.opacity(0.5))
            }
        }
        .containerBackground(for: .widget) {
            ZStack {
                if let filename = entry.backgroundImageFilename,
                   let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen"),
                   let uiImage = UIImage(contentsOfFile: containerURL.appendingPathComponent(filename).path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: entry.gradientColors.map { Color(hex: $0) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0),
                        .init(color: .black.opacity(0.3), location: 0.6),
                        .init(color: .black.opacity(0.2), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var textFont: Font {
        switch family {
        case .systemSmall:
            .system(.callout, design: .serif, weight: .medium)
        case .systemMedium:
            .system(.body, design: .serif, weight: .medium)
        case .systemLarge:
            .system(.title3, design: .serif, weight: .medium)
        default:
            .system(.body, design: .serif, weight: .medium)
        }
    }
}

struct FavoritesWidget: Widget {
    let kind: String = "FavoritesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FavoritesTimelineProvider()) { entry in
            FavoritesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Favorite Affirmations")
        .description("Rotate through your saved favorites throughout the day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Shared types (must match main app)

struct FavoriteWidgetEntry: Codable {
    let text: String
    let gradientColors: [String]
    let backgroundImageFilename: String?
    let textColor: String?
}

struct FavoritesWidgetSnapshot: Codable {
    let favorites: [FavoriteWidgetEntry]
    let updatedAt: Date
}

// MARK: - Widget Bundle

@main
struct LumenWidgetBundle: WidgetBundle {
    var body: some Widget {
        LumenWidget()
        FavoritesWidget()
    }
}

// MARK: - Date Helpers

extension Date {
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
}

