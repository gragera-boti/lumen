import Foundation
import SwiftData

// MARK: - CardCustomization

/// Stores per-affirmation visual overrides for card appearance.
///
/// Design decisions:
/// - Raw values stored as `String` to decouple from enum evolution.
/// - Separate from `Affirmation` so curated content stays clean.
/// - `backgroundSeed` ensures procedural generation produces the same image every time.
/// - `customText` is only settable when the affirmation's source is `.user`.
@Model
final class CardCustomization {
    #Unique<CardCustomization>([\.affirmationId])

    /// The ID of the affirmation this customization applies to.
    var affirmationId: String

    /// Background style override (`GeneratorStyle` raw value, `nil` = use default).
    var backgroundStyle: String?

    /// Color palette override (`ColorPalette` raw value, `nil` = use default).
    var colorPalette: String?

    /// Background seed for procedural generation (ensures same background each time).
    var backgroundSeed: UInt32?

    /// Font style override (`AffirmationFontStyle` raw value, `nil` = use default).
    var fontStyleOverride: String?

    /// AI background prompt ID (from `AIBackgroundPrompt.library`), `nil` = use procedural.
    var aiPromptId: String?

    /// Whether this card uses an AI-generated background instead of procedural.
    var usesAIBackground: Bool

    /// Custom text (only for user-owned affirmations, `nil` = use original).
    var customText: String?

    /// Date this customization was created.
    var createdAt: Date

    /// Date this customization was last updated.
    var updatedAt: Date

    init(
        affirmationId: String,
        backgroundStyle: String? = nil,
        colorPalette: String? = nil,
        backgroundSeed: UInt32? = nil,
        fontStyleOverride: String? = nil,
        aiPromptId: String? = nil,
        usesAIBackground: Bool = false,
        customText: String? = nil
    ) {
        self.affirmationId = affirmationId
        self.backgroundStyle = backgroundStyle
        self.colorPalette = colorPalette
        self.backgroundSeed = backgroundSeed
        self.fontStyleOverride = fontStyleOverride
        self.aiPromptId = aiPromptId
        self.usesAIBackground = usesAIBackground
        self.customText = customText
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
