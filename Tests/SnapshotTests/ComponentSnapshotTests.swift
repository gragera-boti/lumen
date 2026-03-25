import SnapshotTesting
import SwiftUI
import Testing
import UIKit

@testable import Lumen

@MainActor
@Suite("Component Snapshots")
struct ComponentSnapshotTests {

    private let iPhone = ViewImageConfig.iPhone13Pro

    // MARK: - CategoryCardView

    @Test("CategoryCardView standard")
    func categoryCard() {
        let category = Category(
            id: "self-love",
            name: "Self Love",
            categoryDescription: "Embrace who you are",
            icon: "heart.fill"
        )

        let view = ZStack {
            Color.black.ignoresSafeArea()
            CategoryCardView(category: category, action: {})
                .frame(width: 180)
        }

        let host = UIHostingController(rootView: view)
        assertSnapshot(
            of: host,
            as: .image(on: .init(safeArea: .zero, size: CGSize(width: 220, height: 200), traits: .init()))
        )
    }

    @Test("CategoryCardView premium")
    func categoryCardPremium() {
        let category = Category(
            id: "abundance",
            name: "Abundance",
            categoryDescription: "Attract prosperity and growth",
            icon: "sparkles",
            isPremium: true
        )

        let view = ZStack {
            Color.black.ignoresSafeArea()
            CategoryCardView(category: category, action: {})
                .frame(width: 180)
        }

        let host = UIHostingController(rootView: view)
        assertSnapshot(
            of: host,
            as: .image(on: .init(safeArea: .zero, size: CGSize(width: 220, height: 200), traits: .init()))
        )
    }

    // MARK: - CrisisView

    @Test("CrisisView full screen")
    func crisisView() {
        let view = CrisisView()
        let host = UIHostingController(rootView: view)
        assertSnapshot(of: host, as: .image(on: iPhone))
    }

    // MARK: - OnboardingView steps

    @Test("OnboardingView welcome step")
    func onboardingWelcome() {
        let view = OnboardingView(onComplete: {})
        let host = UIHostingController(rootView: view)
        assertSnapshot(of: host, as: .image(on: iPhone))
    }
}
