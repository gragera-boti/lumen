import Foundation

/// On-device ML background generation service.
///
/// Generates calming background images using Core ML Stable Diffusion.
/// Uses restricted prompt templates (no free-form input) for safety.
protocol MLBackgroundServiceProtocol: Sendable {
    /// Check if the current device supports on-device generation.
    func checkCapability() -> GeneratorCapability

    /// Whether the ML model has been downloaded and is ready.
    func isModelReady() async -> Bool

    /// Download the ML model on-demand. Returns progress updates.
    func downloadModel(progress: @escaping @Sendable (Double) -> Void) async throws

    /// Delete the downloaded model to free storage.
    func deleteModel() async throws

    /// Size of the downloaded model in bytes, or nil if not downloaded.
    func modelSizeBytes() async -> UInt64?

    /// Generate a background image from structured parameters.
    /// Throws if cancelled or if generation fails.
    func generate(request: BackgroundGenerationRequest) async throws -> GeneratedBackground

    /// Cancel any in-progress generation.
    func cancelGeneration()
}
