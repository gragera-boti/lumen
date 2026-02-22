import SwiftUI

struct AffirmationCardView: View {
    let affirmation: Affirmation
    let gradientColors: [Color]
    let backgroundImage: UIImage?
    let isFavorited: Bool
    let customization: CardCustomization?
    let onFavorite: () -> Void
    let onShare: () -> Void
    let onEdit: () -> Void

    init(
        affirmation: Affirmation,
        gradientColors: [Color],
        backgroundImage: UIImage? = nil,
        isFavorited: Bool,
        customization: CardCustomization? = nil,
        onFavorite: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onEdit: @escaping () -> Void = {}
    ) {
        self.affirmation = affirmation
        self.gradientColors = gradientColors
        self.backgroundImage = backgroundImage
        self.isFavorited = isFavorited
        self.customization = customization
        self.onFavorite = onFavorite
        self.onShare = onShare
        self.onEdit = onEdit
    }

    /// The display text — uses customText if available (user-owned only), otherwise original.
    private var displayText: String {
        if let custom = customization?.customText, !custom.isEmpty {
            return custom
        }
        return affirmation.text
    }

    /// Font selection — respects customization override, then user-chosen font, then curated defaults.
    private var affirmationFont: Font {
        // Customization font override takes priority
        if let overrideName = customization?.fontStyleOverride,
           let style = AffirmationFontStyle.from( overrideName) {
            return style.cardFont(textLength: displayText.count)
        }

        if let styleName = affirmation.fontStyle,
           let style = AffirmationFontStyle.from( styleName) {
            return style.cardFont(textLength: displayText.count)
        }

        let length = displayText.count
        let style = Self.randomFontStyle(for: affirmation)
        return style.cardFont(textLength: length)
    }

    private static func randomFontStyle(for affirmation: Affirmation) -> AffirmationFontStyle {
        let roll = abs(affirmation.id.hashValue) % 10
        switch roll {
        case 0...3: return .playfair
        case 4...5: return .cormorant
        case 6: return .zilla
        case 7: return .abril
        case 8: return .rounded
        default: return .josefin
        }
    }

    private var letterSpacing: CGFloat {
        if let overrideName = customization?.fontStyleOverride,
           let style = AffirmationFontStyle.from(overrideName) {
            return Self.spacingForStyle(style)
        }
        if let styleName = affirmation.fontStyle,
           let style = AffirmationFontStyle.from(styleName) {
            return Self.spacingForStyle(style)
        }
        return Self.spacingForStyle(Self.randomFontStyle(for: affirmation))
    }

    private static func spacingForStyle(_ style: AffirmationFontStyle) -> CGFloat {
        switch style {
        case .josefin: return 1.5
        case .abril, .playfair: return 0.3
        case .zilla: return 0.2
        default: return 0.5
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

                Text(displayText)
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
                icon: "paintbrush",
                label: "feed.edit".localized,
                action: onEdit
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
        onShare: {},
        onEdit: {}
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
        onShare: {},
        onEdit: {}
    )
    .ignoresSafeArea()
}
