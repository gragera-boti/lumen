import SwiftUI
import WidgetKit

struct WatchComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchComplicationEntry {
        WatchComplicationEntry(date: .now, text: "I can take one small step today.")
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        let entry = loadEntry() ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        let entry = loadEntry() ?? placeholder(in: context)
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        )
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    private func loadEntry() -> WatchComplicationEntry? {
        guard
            let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen"
            )
        else { return nil }

        let fileURL = containerURL.appendingPathComponent("widget_snapshot.json")
        guard let data = try? Data(contentsOf: fileURL),
            let json = try? JSONDecoder().decode(WatchSnapshotData.self, from: data)
        else {
            return nil
        }

        return WatchComplicationEntry(date: json.updatedAt, text: json.text)
    }
}

struct WatchComplicationEntry: TimelineEntry {
    let date: Date
    let text: String
}

private struct WatchSnapshotData: Decodable {
    let text: String
    let updatedAt: Date
}

struct WatchComplicationView: View {
    var entry: WatchComplicationEntry

    var body: some View {
        Text(entry.text)
            .font(.system(.caption2, design: .serif))
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.center)
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [Color(hex: "#7FBBCA"), Color(hex: "#A688B5")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    }
}

struct LumenWatchComplication: Widget {
    let kind = "LumenWatchComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            WatchComplicationView(entry: entry)
        }
        .configurationDisplayName("Lumen")
        .description("Daily affirmation")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner,
        ])
    }
}
