import CoreImage
import OSLog
import UIKit

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
actor AIBackgroundService: AIBackgroundServiceProtocol {
    static let shared = AIBackgroundService()

    private let logger = Logger(subsystem: "com.gragera.lumen", category: "AIBackground")

    private var currentTask: Task<GeneratedBackground, Error>?

    // MARK: - Model Lifecycle

    func isModelReady() async -> Bool {
        true // Always ready since we're using an API
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

    func loadModel() async throws {
        // No-op for API
    }

    func unloadModel() async {
        logger.info("Model unloaded")
    }

    // MARK: - Generation

    func generate(request: AIBackgroundRequest) async throws -> GeneratedBackground {
        let task = Task<GeneratedBackground, Error> {
            try Task.checkCancellation()

            let startTime = CFAbsoluteTimeGetCurrent()
            let seed = request.seed ?? UInt32.random(in: 0...UInt32.max)

            logger.info(
                "Generating AI background: '\(request.prompt.displayName)', seed=\(seed)"
            )

            // Make sure the step handler gets called at least to give UI feedback
            _stepProgressHandler?(0, request.stepCount)
            
            // Prepare prompt and hit Pollinations API
            // Prepare prompt and POST request for Together AI FLUX.1
            let rawPrompt = request.prompt.prompt
            let promptHint = "\(rawPrompt), 9:16 vertical poster background, no text, no words"
            
            guard let url = URL(string: "https://api.together.xyz/v1/images/generations") else {
                throw AIBackgroundError.generationFailed("Invalid API URL")
            }
            
            var requestURL = URLRequest(url: url)
            requestURL.httpMethod = "POST"
            requestURL.setValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("Bearer \(APIKeys.togetherAI)", forHTTPHeaderField: "Authorization")
            
            let jsonPayload: [String: Any] = [
                "model": "black-forest-labs/FLUX.1-schnell",
                "prompt": promptHint,
                "width": 768,
                "height": 1344,
                "steps": 4,
                "n": 1,
                "response_format": "b64_json"
            ]
            
            requestURL.httpBody = try? JSONSerialization.data(withJSONObject: jsonPayload)
            
            // Fetch the image
            let (data, response) = try await URLSession.shared.data(for: requestURL)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIBackgroundError.generationFailed("Invalid response from API")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? ""
                throw AIBackgroundError.generationFailed("Together API returned \(httpResponse.statusCode): \(errorBody)")
            }

            // Parse JSON to get the Base64 image
            guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataArray = jsonResponse["data"] as? [[String: Any]],
                  let firstResult = dataArray.first,
                  let b64String = firstResult["b64_json"] as? String else {
                throw AIBackgroundError.generationFailed("Failed to parse Base64 image from Together response")
            }
            
            guard let imageData = Data(base64Encoded: b64String) else {
                throw AIBackgroundError.generationFailed("Failed to decode Base64 image data")
            }
            
            guard let downloadedImage = UIImage(data: imageData),
                  let cgImage = downloadedImage.cgImage else {
                throw AIBackgroundError.generationFailed("Failed to create image from decoded data")
            }
            
            _stepProgressHandler?(request.stepCount, request.stepCount)

            try Task.checkCancellation()

            // Upscale or just process to native device size
            let nativeSize = request.device.nativeSize
            let upscaledImage = upscale(cgImage: cgImage, to: nativeSize)

            let durationMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

            // Save to disk
            let themeId = "ai_\(UUID().uuidString.prefix(8))"
            let (imagePath, thumbPath) = try saveToDisk(
                image: upscaledImage,
                thumbnail: UIImage(cgImage: cgImage),
                themeId: themeId
            )

            let metadata = GenerationMetadata(
                style: "ai_\(request.prompt.category.rawValue)",
                palette: request.prompt.id,
                mood: request.prompt.category.rawValue,
                seed: seed,
                complexity: 0.5,
                width: Int(nativeSize.width),
                height: Int(nativeSize.height),
                durationMs: durationMs
            )

            logger.info("AI background generated: \(themeId) in \(durationMs)ms")

            let generatedBackground = GeneratedBackground(
                themeId: themeId,
                imagePath: imagePath,
                thumbnailPath: thumbPath,
                metadata: metadata
            )

            // Save to manifest so it appears in AI History
            try saveManifest([generatedBackground])

            return generatedBackground
        }

        currentTask = task
        return try await task.value
    }

    func cancelGeneration() async {
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
            let entries = try? JSONDecoder().decode([CachedEntry].self, from: data)
        else {
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
            var entries = try? JSONDecoder().decode([CachedEntry].self, from: data)
        {
            entries.removeAll { $0.themeId == themeId }
            let updated = try JSONEncoder().encode(entries)
            try updated.write(to: manifestURL)
        }

        logger.info("Removed cached AI background: \(themeId)")
    }

    // MARK: - Image Processing

    /// Upscale a square SD image to fill a portrait target, then center-crop.
    /// This avoids stretching — the image is uniformly scaled to cover the
    /// target frame, then the excess is trimmed from the edges.
    private func upscale(cgImage: CGImage, to targetSize: CGSize) -> UIImage {
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: [.useSoftwareRenderer: false])

        let sourceWidth = CGFloat(cgImage.width)
        let sourceHeight = CGFloat(cgImage.height)

        // Scale uniformly to COVER the target (no distortion)
        let scale = max(targetSize.width / sourceWidth, targetSize.height / sourceHeight)

        // Use Lanczos for sharp upscaling (aspect ratio = 1.0 to keep uniform)
        let scaledImage: CIImage
        if let filter = CIFilter(name: "CILanczosScaleTransform") {
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            filter.setValue(Float(scale), forKey: kCIInputScaleKey)
            filter.setValue(1.0, forKey: kCIInputAspectRatioKey)  // Uniform — no distortion
            scaledImage = filter.outputImage ?? ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        } else {
            scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        }

        // Center-crop to target size, clamped to scaled bounds to avoid out-of-bounds CIContext failures
        let scaledWidth = sourceWidth * scale
        let scaledHeight = sourceHeight * scale
        let cropW = min(targetSize.width, scaledWidth)
        let cropH = min(targetSize.height, scaledHeight)
        let cropX = max(0, (scaledWidth - cropW) / 2)
        let cropY = max(0, (scaledHeight - cropH) / 2)
        let cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)

        guard let croppedCG = context.createCGImage(scaledImage, from: cropRect) else {
            return UIImage(cgImage: cgImage)
        }

        // If the cropped image is slightly smaller than target (rounding), scale to exact target
        if abs(cropW - targetSize.width) > 1 || abs(cropH - targetSize.height) > 1 {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                UIImage(cgImage: croppedCG).draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }

        let outputCG = croppedCG

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
            let existing = try? JSONDecoder().decode([CachedEntry].self, from: data)
        {
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
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
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
