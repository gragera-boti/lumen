import XCTest
@testable import Lumen

final class AIBackgroundServiceTests: XCTestCase {

    private final class StepTracker: @unchecked Sendable {
        private let lock = NSLock()
        private var _steps: [(Int, Int)] = []

        var steps: [(Int, Int)] {
            lock.withLock { _steps }
        }

        func record(step: Int, total: Int) {
            lock.withLock { _steps.append((step, total)) }
        }
    }

    func test_modelLoadAndGenerate() async throws {
        let service = AIBackgroundService.shared
        let tracker = StepTracker()

        await service.setStepProgressHandler { step, total in
            tracker.record(step: step, total: total)
        }

        // Load model
        do {
            try await service.loadModel()
        } catch {
            XCTFail("Model load failed: \(error)")
            return
        }

        let ready = await service.isModelReady()
        XCTAssertTrue(ready, "Model should be ready after loading")

        // Generate a single image with minimal steps
        let request = AIBackgroundRequest(
            prompt: .random(),
            stepCount: 4,
            device: AIDeviceProfile(screenWidth: 390, screenHeight: 844, screenScale: 3)
        )

        do {
            let result = try await service.generate(request: request)
            XCTAssertFalse(result.themeId.isEmpty)
            XCTAssertTrue(FileManager.default.fileExists(atPath: result.imagePath.path))
            let stepCount = tracker.steps.count
            XCTAssertTrue(stepCount >= 4, "Should have received at least 4 step callbacks, got \(stepCount)")
            print("✅ Generated: \(result.themeId), steps reported: \(stepCount), duration: \(result.metadata.durationMs)ms")
        } catch {
            XCTFail("Generation failed: \(error)")
        }

        await service.setStepProgressHandler(nil)
    }
}
