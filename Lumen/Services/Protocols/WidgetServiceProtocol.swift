import Foundation

/// Widget data update service protocol.
protocol WidgetServiceProtocol: Sendable {
    /// Write a snapshot to the shared App Group container and reload widget timelines.
    func updateWidget(affirmationText: String, gradientColors: [String])

    /// Write favorites data for the favorites widget.
    func updateFavoritesWidget(favorites: [(text: String, gradientColors: [String])])
}
