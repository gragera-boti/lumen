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
            forSecurityApplicationGroupIdentifier: "group.com.lumen.app"
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

// MARK: - Widget Bundle

@main
struct LumenWidgetBundle: WidgetBundle {
    var body: some Widget {
        LumenWidget()
    }
}

// MARK: - Color extension for widget (self-contained)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

extension Date {
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
