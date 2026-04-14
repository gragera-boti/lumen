import Foundation
import UIKit

/// Widget data update service protocol.
protocol WidgetServiceProtocol: Sendable {
    /// Write snapshots to the shared App Group container and reload widget timelines.
    /// - Parameters:
    ///   - entries: An array of affirmations with text, gradient colors, and optional background images.
    func updateWidget(entries: [(text: String, fontStyle: String?, gradientColors: [String], backgroundImage: UIImage?, textColor: String?, imageAlignmentX: Double?, imageAlignmentY: Double?)])

    /// Write favorites data to the shared App Group container and reload the favorites widget.
    /// - Parameter favorites: An array of tuples containing affirmation text, gradient colors, and optional background images.
    func updateFavoritesWidget(favorites: [(text: String, fontStyle: String?, gradientColors: [String], backgroundImage: UIImage?, textColor: String?, imageAlignmentX: Double?, imageAlignmentY: Double?)])
}
