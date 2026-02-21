import SwiftUI

struct AffirmationCardView: View {
    let affirmation: Affirmation
    let gradientColors: [Color]
    let backgroundImage: UIImage?
    let isFavorited: Bool
    let onFavorite: () -> Void
    let onShare: () -> Void

    init(
        affirmation: Affirmation,
        gradientColors: [Color],
        backgroundImage: UIImage? = nil,
        isFavorited: Bool,
        onFavorite: @escaping () -> Void,
        onShare: @escaping () -> Void
    ) {
        self.affirmation = affirmation
        self.gradientColors = gradientColors
        self.backgroundImage = backgroundImage
        self.isFavorited = isFavorited
        self.onFavorite = onFavorite
        self.onShare = onShare
    }

    /// Font selection — respects user-chosen font for custom affirmations,
    /// otherwise uses curated defaults (primarily New York serif).
    private var affirmationFont: Font {
        if let styleName = affirmation.fontStyle,
           let style = AffirmationFontStyle(rawValue: styleName) {
            return style.cardFont(textLength: affirmation.text.count)
        }

        let length = affirmation.text.count
        let design = Self.fontDesign(for: affirmation)
        let weight = Self.fontWeight(for: affirmation)

        if length < 40 { return .system(size: 34, weight: weight, design: design) }
        else if length < 80 { return .system(size: 28, weight: weight, design: design) }
        else if length < 140 { return .system(size: 24, weight: weight, design: design) }
        else { return .system(size: 21, weight: weight, design: design) }
    }

    private static func fontDesign(for aff: Affirmation) -> Font.Design {
        let hash = abs(aff.id.hashValue)
        let roll = hash % 10
        if roll < 7 { return .serif }
        if roll < 9 { return .rounded }
        return .default
    }

    private static func fontWeight(for aff: Affirmation) -> Font.Weight {
        let hash = abs(aff.id.hashValue >> 4)
        let weights: [Font.Weight] = [.medium, .regular, .medium, .semibold, .regular]
        return weights[hash % weights.count]
    }

    private var letterSpacing: CGFloat {
        if let styleName = affirmation.fontStyle,
           let _ = AffirmationFontStyle(rawValue: styleName) {
            return 0.3
        }
        let design = Self.fontDesign(for: affirmation)
        switch design {
        case .serif: return 0.3
        case .rounded: return 0.5
        default: return 0.2
        }
    }

    var body: some View {
        ZStack {
            if let bgImage = backgroundImage {
                Image(uiImage: bgImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            ReadabilityOverlay()

            VStack {
                Spacer()

                Text(affirmation.text)
                    .font(affirmationFont)
                    .tracking(letterSpacing)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, LumenTheme.Spacing.xl + LumenTheme.Spacing.md)
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                actionBar
                    .padding(.bottom, 120)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("affirmation_card")
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: LumenTheme.Spacing.xl) {
            ActionButton(
                icon: isFavorited ? "heart.fill" : "heart",
                label: "feed.favorite".localized,
                isActive: isFavorited,
                action: onFavorite
            )

            ActionButton(
                icon: "square.and.arrow.up",
                label: "feed.share".localized,
                action: onShare
            )
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: LumenTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .symbolEffect(.bounce, value: isActive)

                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(.white)
            .frame(minWidth: 60, minHeight: 44)
        }
        .accessibilityLabel(label)
        .accessibilityHint(isActive ? "Currently active" : "Tap to activate")
    }
}

// MARK: - Preview

#Preview("Affirmation Card") {
    AffirmationCardView(
        affirmation: Affirmation(
            id: "preview_1",
            text: "I am worthy of love and kindness",
            tone: .gentle,
            intensity: .low
        ),
        gradientColors: [.teal, .blue],
        isFavorited: false,
        onFavorite: {},
        onShare: {}
    )
    .ignoresSafeArea()
}

#Preview("Favorited Card") {
    AffirmationCardView(
        affirmation: Affirmation(
            id: "preview_2",
            text: "Every step I take brings me closer to my goals",
            tone: .energetic,
            intensity: .medium
        ),
        gradientColors: [.orange, .pink],
        isFavorited: true,
        onFavorite: {},
        onShare: {}
    )
    .ignoresSafeArea()
}
