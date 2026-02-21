import UIKit

/// Procedural background image generator.
///
/// Creates beautiful, calming background images entirely on-device
/// using Core Graphics — no ML models, no downloads, instant results.
protocol BackgroundGeneratorProtocol: Sendable {
    /// Generate a background image from structured parameters.
    func generate(request: BackgroundRequest) async throws -> GeneratedBackground

    /// Cancel any in-progress generation.
    func cancelGeneration()
}
