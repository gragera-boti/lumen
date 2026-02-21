import WidgetKit
import SwiftUI

// MARK: - Widget Data

struct WidgetAffirmation: Codable {
    let id: String
    let text: String
    let gradientColors: [String]
    let updatedAt: Date
}

// MARK: - Timeline Provider

struct LumenTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> LumenEntry {
        LumenEntry(
            date: .now,
            affirmationText: "I can take one small step today.",
            gradientColors: ["#7FBBCA", "#A688B5"]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LumenEntry) -> Void) {
        let entry = loadEntry() ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LumenEntry>) -> Void) {
        let entry = loadEntry() ?? placeholder(in: context)

        // Refresh at midnight
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date().adding(days: 1))
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    private func loadEntry() -> LumenEntry? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen"
        ) else { return nil }

        let fileURL = containerURL.appendingPathComponent("widget_snapshot.json")
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(WidgetAffirmation.self, from: data) else {
            return nil
        }

        return LumenEntry(
            date: snapshot.updatedAt,
            affirmationText: snapshot.text,
            gradientColors: snapshot.gradientColors
        )
    }
}

// MARK: - Timeline Entry

struct LumenEntry: TimelineEntry {
    let date: Date
    let affirmationText: String
    let gradientColors: [String]
}

// MARK: - Widget Views

struct LumenWidgetEntryView: View {
    var entry: LumenEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            LinearGradient(
                colors: entry.gradientColors.map { Color(hex: $0) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

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

            VStack {
                Spacer()

                Text(entry.affirmationText)
                    .font(textFont)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                    .minimumScaleFactor(0.7)

                Spacer()

                if family != .systemSmall {
                    Text("Lumen")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 8)
                }
            }
            .padding(8)
        }
        .containerBackground(for: .widget) {
            Color.clear
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
        FavoritesEntry(
            date: .now,
            affirmationText: "You are worthy of love and kindness.",
            gradientColors: ["#A688B5", "#E8837C"]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FavoritesEntry) -> Void) {
        let entry = loadRandomEntry() ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoritesEntry>) -> Void) {
        let favorites = loadFavorites()
        guard !favorites.isEmpty else {
            let entry = placeholder(in: context)
            let timeline = Timeline(entries: [entry], policy: .after(Date().adding(hours: 1)))
            completion(timeline)
            return
        }

        // Create entries that rotate every 30 minutes
        var entries: [FavoritesEntry] = []
        let now = Date()
        for i in 0..<min(favorites.count, 48) {
            let entryDate = now.adding(minutes: i * 30)
            let fav = favorites[i % favorites.count]
            entries.append(FavoritesEntry(
                date: entryDate,
                affirmationText: fav.text,
                gradientColors: fav.gradientColors
            ))
        }

        let timeline = Timeline(entries: entries, policy: .after(now.adding(hours: 24)))
        completion(timeline)
    }

    private func loadFavorites() -> [FavoriteWidgetEntry] {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen"
        ) else { return [] }

        let fileURL = containerURL.appendingPathComponent("favorites_widget.json")
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(FavoritesWidgetSnapshot.self, from: data) else {
            return []
        }
        return snapshot.favorites.shuffled()
    }

    private func loadRandomEntry() -> FavoritesEntry? {
        guard let fav = loadFavorites().randomElement() else { return nil }
        return FavoritesEntry(
            date: .now,
            affirmationText: fav.text,
            gradientColors: fav.gradientColors
        )
    }
}

struct FavoritesEntry: TimelineEntry {
    let date: Date
    let affirmationText: String
    let gradientColors: [String]
}

struct FavoritesWidgetEntryView: View {
    var entry: FavoritesEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            LinearGradient(
                colors: entry.gradientColors.map { Color(hex: $0) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0), location: 0),
                    .init(color: .black.opacity(0.3), location: 0.6),
                    .init(color: .black.opacity(0.2), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                Spacer()

                Text(entry.affirmationText)
                    .font(textFont)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
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
                .padding(.bottom, 8)
            }
            .padding(8)
        }
        .containerBackground(for: .widget) {
            Color.clear
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

// Color(hex:) is provided by the shared Color+Hex.swift extension

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
