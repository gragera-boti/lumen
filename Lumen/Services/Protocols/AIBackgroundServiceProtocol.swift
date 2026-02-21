import UIKit

/// On-device AI background generation using Core ML Stable Diffusion.
///
/// Generates unique, vibrant abstract backgrounds using a quantized SD model.
/// Designed as a premium complement to the instant procedural generator.
protocol AIBackgroundServiceProtocol: Sendable {
    /// Whether the ML model is loaded and ready to generate.
    func isModelReady() async -> Bool

    /// Set a callback for ODR download progress (0.0–1.0). Only fires in Release builds.
    func setDownloadProgressHandler(_ handler: (@Sendable (Double) -> Void)?)

    /// Set a callback for generation step progress (step/totalSteps).
    func setStepProgressHandler(_ handler: (@Sendable (Int, Int) -> Void)?)

    /// Set a callback for model loading phase ("Loading TextEncoder…", etc.)
    func setLoadPhaseHandler(_ handler: (@Sendable (String, Double) -> Void)?)

    /// Load the ML model into memory. Call before first generation.
    /// In Release builds, this may trigger an On-Demand Resource download first.
    func loadModel() async throws

    /// Unload the ML model to free memory.
    func unloadModel() async

    /// Generate a single AI background image.
    func generate(request: AIBackgroundRequest) async throws -> GeneratedBackground

    /// Cancel any in-progress generation.
    func cancelGeneration() async

    /// Pre-generate a batch of backgrounds and cache them for instant access.
    func pregenerate(count: Int, device: AIDeviceProfile) async throws -> [GeneratedBackground]

    /// Return cached AI backgrounds available for immediate use.
    func cachedBackgrounds() async -> [GeneratedBackground]

    /// Remove a cached background by theme ID.
    func removeCached(themeId: String) async throws
}

// MARK: - Request

struct AIBackgroundRequest: Sendable {
    let prompt: AIBackgroundPrompt
    let seed: UInt32?
    let stepCount: Int
    let device: AIDeviceProfile

    init(
        prompt: AIBackgroundPrompt = .random(),
        seed: UInt32? = nil,
        stepCount: Int = 10,
        device: AIDeviceProfile = .current()
    ) {
        self.prompt = prompt
        self.seed = seed
        self.stepCount = stepCount
        self.device = device
    }
}

// MARK: - Device profile for adaptive resolution

struct AIDeviceProfile: Sendable {
    let screenWidth: Int
    let screenHeight: Int
    let screenScale: Int

    /// Native pixel resolution for full-screen backgrounds
    var nativeSize: CGSize {
        CGSize(width: screenWidth * screenScale, height: screenHeight * screenScale)
    }

    /// Capped generation size — we generate at 512×512 and upscale
    var generationSize: CGSize {
        CGSize(width: 512, height: 512)
    }

    static func current() -> AIDeviceProfile {
        let screen = UIScreen.main
        return AIDeviceProfile(
            screenWidth: Int(screen.bounds.width),
            screenHeight: Int(screen.bounds.height),
            screenScale: Int(screen.scale)
        )
    }
}

// MARK: - Errors

enum AIBackgroundError: Error, LocalizedError {
    case modelNotLoaded
    case modelLoadFailed(String)
    case generationFailed(String)
    case cancelled
    case insufficientMemory
    case deviceNotSupported

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: "AI model is not loaded. Please wait for it to finish loading."
        case .modelLoadFailed(let reason): "Could not load AI model: \(reason)"
        case .generationFailed(let reason): "AI generation failed: \(reason)"
        case .cancelled: "Generation was cancelled."
        case .insufficientMemory: "Not enough memory to run AI generation. Try closing other apps."
        case .deviceNotSupported: "This device doesn't support AI background generation."
        }
    }
}
