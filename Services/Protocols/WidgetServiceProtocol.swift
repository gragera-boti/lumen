import Foundation

/// Widget data update service protocol.
protocol WidgetServiceProtocol: Sendable {
    /// Write a snapshot to the shared App Group container and reload widget timelines.
    /// - Parameters:
    ///   - affirmationText: The affirmation text to display in the widget.
    ///   - gradientColors: Hex color strings for the widget's gradient background.
    func updateWidget(affirmationText: String, gradientColors: [String])

    /// Write favorites data to the shared App Group container and reload the favorites widget.
    /// - Parameter favorites: An array of tuples containing affirmation text and gradient color hex strings.
    func updateFavoritesWidget(favorites: [(text: String, gradientColors: [String])])
}
