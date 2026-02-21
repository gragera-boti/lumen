import UIKit
import CoreML
import StableDiffusion
import CoreImage
import OSLog

/// On-device AI background generator using Core ML Stable Diffusion.
///
/// Generates 512×512 images via a quantized SD 1.4 model, then upscales
/// to device-native resolution using Core Image Lanczos. Results are cached
/// on disk for instant access in the feed.
///
/// Architecture:
/// - Model is loaded lazily on first generation request
/// - Generation runs on a background actor to avoid blocking UI
/// - Cached backgrounds are stored in the app group container
/// - Pre-generation batch runs silently in the background
actor AIBackgroundService: @preconcurrency AIBackgroundServiceProtocol {
    static let shared = AIBackgroundService()

    private let logger = Logger(subsystem: "com.gragera.lumen", category: "AIBackground")

    private var pipeline: StableDiffusionPipeline?
    private var isLoading = false
    private var currentTask: Task<GeneratedBackground, Error>?

    // MARK: - Model Lifecycle

    func isModelReady() async -> Bool {
        pipeline != nil
    }

    /// Progress callback for ODR download (0.0–1.0), observed from ViewModel
    /// nonisolated to allow setting from any actor without hopping
    private nonisolated(unsafe) var _downloadProgressHandler: (@Sendable (Double) -> Void)?
    private nonisolated(unsafe) var _stepProgressHandler: (@Sendable (Int, Int) -> Void)?
    private nonisolated(unsafe) var _loadPhaseHandler: (@Sendable (String, Double) -> Void)?

    nonisolated func setDownloadProgressHandler(_ handler: (@Sendable (Double) -> Void)?) {
        _downloadProgressHandler = handler
    }

    nonisolated func setStepProgressHandler(_ handler: (@Sendable (Int, Int) -> Void)?) {
        _stepProgressHandler = handler
    }

    nonisolated func setLoadPhaseHandler(_ handler: (@Sendable (String, Double) -> Void)?) {
        _loadPhaseHandler = handler
    }

    private var downloadProgressHandler: (@Sendable (Double) -> Void)? {
        _downloadProgressHandler
    }

    private var stepProgressHandler: (@Sendable (Int, Int) -> Void)? {
        _stepProgressHandler
    }

    private var loadPhaseHandler: (@Sendable (String, Double) -> Void)? {
        _loadPhaseHandler
    }

    func loadModel() async throws {
        guard pipeline == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        logger.info("Loading Stable Diffusion model…")

        // Resolve model URL — bundled in Debug, ODR in Release
        let modelURL = try await resolveModelResources()

        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine

        do {
            logger.info("Creating pipeline from: \(modelURL.path)")

            // List what's in the model directory
            let contents = (try? FileManager.default.contentsOfDirectory(atPath: modelURL.path)) ?? []
            logger.info("Model directory contents (\(contents.count) items): \(contents.filter { $0.hasSuffix(".mlmodelc") || $0.hasSuffix(".json") || $0.hasSuffix(".txt") }.joined(separator: ", "))")

            // Check available memory before loading
            let memInfo = ProcessInfo.processInfo.physicalMemory
            let taskInfo = mach_task_self_
            var info = task_vm_info_data_t()
            var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
            let kr = withUnsafeMutablePointer(to: &info) { ptr in
                ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                    task_info(taskInfo, task_flavor_t(TASK_VM_INFO), intPtr, &count)
                }
            }
            if kr == KERN_SUCCESS {
                let usedMB = info.phys_footprint / (1024 * 1024)
                let totalMB = memInfo / (1024 * 1024)
                logger.info("Memory before model load: \(usedMB)MB used / \(totalMB)MB total")
            }

            let phaseHandler = self.loadPhaseHandler

            phaseHandler?("Creating pipeline…", 0.05)
            let pipe = try StableDiffusionPipeline(
                resourcesAt: modelURL,
                controlNet: [],
                configuration: config,
                disableSafety: true,
                reduceMemory: true
            )

            logger.info("Pipeline created, loading resources…")

            // loadResources() loads TextEncoder + Unet + Decoder sequentially.
            // We can't get per-model progress from the public API, but we signal
            // a "Loading models…" phase so the UI shows an indeterminate bar
            // with a descriptive message instead of appearing stuck.
            phaseHandler?("Loading AI models (this takes a moment the first time)…", 0.1)
            try pipe.loadResources()

            phaseHandler?("Ready", 1.0)
            self.pipeline = pipe
            logger.info("All model resources loaded successfully")
        } catch {
            logger.error("Model load failed: \(error)")
            logger.error("Model load error description: \(error.localizedDescription)")
            throw AIBackgroundError.modelLoadFailed(error.localizedDescription)
        }
    }

    // MARK: - Resource Resolution (Bundle vs ODR)

    private func resolveModelResources() async throws -> URL {
        // Try named subdirectory first
        if let bundleURL = Bundle.main.url(forResource: "CoreMLStableDiffusion", withExtension: nil) {
            logger.info("Model found in bundle subdirectory")
            return bundleURL
        }

        // Try bundle root (XcodeGen flattens resources)
        if Bundle.main.url(forResource: "Unet", withExtension: "mlmodelc") != nil {
            logger.info("Model found at bundle root")
            return Bundle.main.bundleURL
        }

        // Fall back to On-Demand Resource request (Release builds)
        logger.info("Model not in bundle, requesting via On-Demand Resources…")
        return try await requestODRResources()
    }

    private var odrRequest: NSBundleResourceRequest?

    private func requestODRResources() async throws -> URL {
        let request = NSBundleResourceRequest(tags: ["ai-model"])
        self.odrRequest = request // retain to keep resources available

        // Check if already available
        let isAvailable = await request.conditionallyBeginAccessingResources()
        if isAvailable {
            logger.info("ODR resources already cached")
            return resolveModelURL(in: request.bundle)
        }

        // Download with progress
        logger.info("Downloading AI model via ODR…")
        downloadProgressHandler?(0.0)

        // Capture handler outside actor isolation for KVO callback
        let handler = downloadProgressHandler

        // Observe progress
        let observation = request.progress.observe(\.fractionCompleted) { progress, _ in
            let fraction = progress.fractionCompleted
            handler?(fraction)
        }

        do {
            try await request.beginAccessingResources()
            observation.invalidate()
            handler?(1.0)
            logger.info("ODR download complete")
            return resolveModelURL(in: request.bundle)
        } catch {
            observation.invalidate()
            handler?(0.0)
            logger.error("ODR download failed: \(error.localizedDescription)")
            throw AIBackgroundError.modelLoadFailed("Failed to download AI model: \(error.localizedDescription)")
        }
    }

    private func resolveModelURL(in bundle: Bundle) -> URL {
        // ODR resources land in the bundle, find the directory
        if let url = bundle.url(forResource: "CoreMLStableDiffusion", withExtension: nil) {
            return url
        }
        // Fallback: search for Unet.mlmodelc and use its parent
        if let unetURL = bundle.url(forResource: "Unet", withExtension: "mlmodelc") {
            return unetURL.deletingLastPathComponent()
        }
        return bundle.bundleURL
    }

    func unloadModel() async {
        pipeline = nil
        logger.info("Model unloaded")
    }

    // MARK: - Generation

    func generate(request: AIBackgroundRequest) async throws -> GeneratedBackground {
        guard let pipe = pipeline else {
            throw AIBackgroundError.modelNotLoaded
        }

        let task = Task<GeneratedBackground, Error> {
            try Task.checkCancellation()

            let startTime = CFAbsoluteTimeGetCurrent()
            let seed = request.seed ?? UInt32.random(in: 0...UInt32.max)

            logger.info("Generating AI background: '\(request.prompt.displayName)', seed=\(seed), steps=\(request.stepCount)")

            var pipelineConfig = StableDiffusionPipeline.Configuration(prompt: request.prompt.prompt)
            pipelineConfig.negativePrompt = request.prompt.negativePrompt
            pipelineConfig.seed = seed
            pipelineConfig.stepCount = request.stepCount
            pipelineConfig.guidanceScale = 7.5
            pipelineConfig.schedulerType = .dpmSolverMultistepScheduler

            let stepHandler = self.stepProgressHandler
            // Signal step 0 to indicate we're about to start (models will lazy-load)
            self.logger.info("Starting generation — models will lazy-load on first use")
            stepHandler?(0, request.stepCount)

            let images = try pipe.generateImages(configuration: pipelineConfig) { progress in
                // step is 0-indexed from the library, add 1 for display
                let displayStep = progress.step + 1
                self.logger.info("Generation step \(displayStep)/\(progress.stepCount)")
                stepHandler?(displayStep, progress.stepCount)
                return !Task.isCancelled
            }

            try Task.checkCancellation()

            guard let cgImage = images.first, let unwrapped = cgImage else {
                throw AIBackgroundError.generationFailed("No image produced")
            }

            // Upscale from 512×512 to device resolution
            let nativeSize = request.device.nativeSize
            let upscaledImage = upscale(cgImage: unwrapped, to: nativeSize)

            let durationMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

            // Save to disk
            let themeId = "ai_\(UUID().uuidString.prefix(8))"
            let (imagePath, thumbPath) = try saveToDisk(image: upscaledImage, thumbnail: UIImage(cgImage: unwrapped), themeId: themeId)

            let metadata = GenerationMetadata(
                style: "ai_\(request.prompt.category.rawValue)",
                palette: request.prompt.id,
                mood: request.prompt.category.rawValue,
                seed: seed,
                complexity: Float(request.stepCount) / 20.0,
                width: Int(nativeSize.width),
                height: Int(nativeSize.height),
                durationMs: durationMs
            )

            logger.info("AI background generated: \(themeId) in \(durationMs)ms")

            return GeneratedBackground(
                themeId: themeId,
                imagePath: imagePath,
                thumbnailPath: thumbPath,
                metadata: metadata
            )
        }

        currentTask = task
        return try await task.value
    }

    func cancelGeneration() {
        currentTask?.cancel()
        currentTask = nil
    }

    // MARK: - Batch Pre-generation

    func pregenerate(count: Int, device: AIDeviceProfile) async throws -> [GeneratedBackground] {
        var results: [GeneratedBackground] = []

        // Use diverse categories for visual variety
        let categories = AIBackgroundPrompt.PromptCategory.allCases
        var categoryIndex = 0

        for i in 0..<count {
            try Task.checkCancellation()

            let category = categories[categoryIndex % categories.count]
            categoryIndex += 1

            let request = AIBackgroundRequest(
                prompt: .random(category: category),
                stepCount: 10,
                device: device
            )

            do {
                let bg = try await generate(request: request)
                results.append(bg)
                logger.info("Pre-generated \(i + 1)/\(count): \(bg.themeId)")
            } catch {
                logger.warning("Pre-generation \(i + 1) failed: \(error.localizedDescription)")
                // Continue with remaining — don't fail the whole batch
            }
        }

        // Write manifest
        try saveManifest(results)

        return results
    }

    // MARK: - Cache Management

    func cachedBackgrounds() async -> [GeneratedBackground] {
        let dir = aiThemesDirectory()
        let manifestURL = dir.appendingPathComponent("manifest.json")

        guard let data = try? Data(contentsOf: manifestURL),
              let entries = try? JSONDecoder().decode([CachedEntry].self, from: data) else {
            return []
        }

        return entries.compactMap { entry in
            let imagePath = dir.appendingPathComponent(entry.imageFilename)
            let thumbPath = dir.appendingPathComponent(entry.thumbFilename)
            guard FileManager.default.fileExists(atPath: imagePath.path) else { return nil }

            return GeneratedBackground(
                themeId: entry.themeId,
                imagePath: imagePath,
                thumbnailPath: thumbPath,
                metadata: entry.metadata
            )
        }
    }

    func removeCached(themeId: String) async throws {
        let dir = aiThemesDirectory()
        let fm = FileManager.default

        try? fm.removeItem(at: dir.appendingPathComponent("\(themeId).jpg"))
        try? fm.removeItem(at: dir.appendingPathComponent("\(themeId)_thumb.jpg"))

        // Update manifest
        let manifestURL = dir.appendingPathComponent("manifest.json")
        if let data = try? Data(contentsOf: manifestURL),
           var entries = try? JSONDecoder().decode([CachedEntry].self, from: data) {
            entries.removeAll { $0.themeId == themeId }
            let updated = try JSONEncoder().encode(entries)
            try updated.write(to: manifestURL)
        }

        logger.info("Removed cached AI background: \(themeId)")
    }

    // MARK: - Image Processing

    private func upscale(cgImage: CGImage, to targetSize: CGSize) -> UIImage {
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: [.useSoftwareRenderer: false])

        let scaleX = targetSize.width / CGFloat(cgImage.width)
        let scaleY = targetSize.height / CGFloat(cgImage.height)
        let scale = max(scaleX, scaleY)

        // Use Lanczos scale filter for sharp upscaling
        guard let filter = CIFilter(name: "CILanczosScaleTransform") else {
            // Fallback: simple affine transform
            let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            let outputRect = CGRect(origin: .zero, size: targetSize)
            guard let outputCG = context.createCGImage(scaled, from: outputRect) else {
                return UIImage(cgImage: cgImage)
            }
            return UIImage(cgImage: outputCG)
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        filter.setValue(scaleX / scaleY, forKey: kCIInputAspectRatioKey)

        let outputImage = filter.outputImage ?? ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        let outputRect = CGRect(origin: .zero, size: targetSize)

        guard let outputCG = context.createCGImage(outputImage, from: outputRect) else {
            return UIImage(cgImage: cgImage)
        }

        return UIImage(cgImage: outputCG)
    }

    // MARK: - File Management

    private func saveToDisk(image: UIImage, thumbnail: UIImage, themeId: String) throws -> (URL, URL) {
        let dir = aiThemesDirectory()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let imagePath = dir.appendingPathComponent("\(themeId).jpg")
        let thumbPath = dir.appendingPathComponent("\(themeId)_thumb.jpg")

        // Full resolution as JPEG (much smaller than PNG for photographic content)
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw AIBackgroundError.generationFailed("Could not encode image")
        }
        try imageData.write(to: imagePath)

        // Thumbnail at 256px
        let thumbSize = CGSize(width: 256, height: 256)
        let thumbRenderer = UIGraphicsImageRenderer(size: thumbSize)
        let thumbData = thumbRenderer.jpegData(withCompressionQuality: 0.8) { ctx in
            thumbnail.draw(in: CGRect(origin: .zero, size: thumbSize))
        }
        try thumbData.write(to: thumbPath)

        return (imagePath, thumbPath)
    }

    private func saveManifest(_ backgrounds: [GeneratedBackground]) throws {
        let dir = aiThemesDirectory()
        let manifestURL = dir.appendingPathComponent("manifest.json")

        // Load existing entries and append
        var entries: [CachedEntry] = []
        if let data = try? Data(contentsOf: manifestURL),
           let existing = try? JSONDecoder().decode([CachedEntry].self, from: data) {
            entries = existing
        }

        for bg in backgrounds {
            let entry = CachedEntry(
                themeId: bg.themeId,
                imageFilename: "\(bg.themeId).jpg",
                thumbFilename: "\(bg.themeId)_thumb.jpg",
                metadata: bg.metadata,
                createdAt: Date()
            )
            entries.append(entry)
        }

        let data = try JSONEncoder().encode(entries)
        try data.write(to: manifestURL)
    }

    private func aiThemesDirectory() -> URL {
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen"
        ) {
            return container.appendingPathComponent("themes/ai")
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("themes/ai")
    }
}

// MARK: - Cache manifest entry

private struct CachedEntry: Codable {
    let themeId: String
    let imageFilename: String
    let thumbFilename: String
    let metadata: GenerationMetadata
    let createdAt: Date
}
