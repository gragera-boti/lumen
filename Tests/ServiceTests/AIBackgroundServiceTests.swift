import Foundation
import Testing

@testable import Lumen

@Suite("AIBackgroundService Tests")
@MainActor struct AIBackgroundServiceTests {

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

    @Test("Model load and generate")
    func modelLoadAndGenerate() async throws {
        let service = AIBackgroundService.shared
        let tracker = StepTracker()

        service.setStepProgressHandler { step, total in
            tracker.record(step: step, total: total)
        }

        try await service.loadModel()

        let ready = await service.isModelReady()
        #expect(ready, "Model should be ready after loading")

        let request = AIBackgroundRequest(
            prompt: .random(),
            stepCount: 4,
            device: AIDeviceProfile(screenWidth: 390, screenHeight: 844, screenScale: 3)
        )

        let result = try await service.generate(request: request)
        #expect(!result.themeId.isEmpty)
        #expect(FileManager.default.fileExists(atPath: result.imagePath.path))
        let stepCount = tracker.steps.count
        #expect(stepCount == 2, "Should have received exactly 2 step callbacks (start/end), got \(stepCount)")
        print("✅ Generated: \(result.themeId), steps reported: \(stepCount), duration: \(result.metadata.durationMs)ms")

        service.setStepProgressHandler(nil)
    }
}
