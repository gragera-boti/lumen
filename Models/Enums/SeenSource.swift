import Foundation

enum SeenSource: String, Codable {
    case feed = "FEED"
    case widget = "WIDGET"
    case notification = "NOTIFICATION"
    case category = "CATEGORY"
}
