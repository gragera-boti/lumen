import Foundation

struct ContentFilters: Codable, Equatable {
    var spiritual: Bool
    var manifestation: Bool
    var bodyFocus: Bool

    static let defaults = ContentFilters(
        spiritual: false,
        manifestation: false,
        bodyFocus: false
    )
}
