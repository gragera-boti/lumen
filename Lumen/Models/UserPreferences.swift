import Foundation
import SwiftData

@Model
final class UserPreferences {
    @Attribute(.unique) var id: Int = 1
    var locale: String
    var tonePreset: Tone
    var gentleMode: Bool
    var selectedCategoryIds: [String]
    var includeSensitiveTopics: Bool
    var contentFiltersData: Data
    var remindersData: Data
    var voiceData: Data
    var themeId: String?
    var analyticsOptOut: Bool
    var hasCompletedOnboarding: Bool
    var updatedAt: Date

    init(
        locale: String = "en-GB",
        tonePreset: Tone = .gentle,
        gentleMode: Bool = true,
        selectedCategoryIds: [String] = [],
        includeSensitiveTopics: Bool = false,
        contentFilters: ContentFilters = .defaults,
        reminders: ReminderSettings = .defaults,
        themeId: String? = nil,
        analyticsOptOut: Bool = false,
        hasCompletedOnboarding: Bool = false
    ) {
        self.locale = locale
        self.tonePreset = tonePreset
        self.gentleMode = gentleMode
        self.selectedCategoryIds = selectedCategoryIds
        self.includeSensitiveTopics = includeSensitiveTopics
        self.contentFiltersData = (try? JSONEncoder().encode(contentFilters)) ?? Data()
        self.remindersData = (try? JSONEncoder().encode(reminders)) ?? Data()
        self.voiceData = Data()
        self.themeId = themeId
        self.analyticsOptOut = analyticsOptOut
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.updatedAt = .now
    }

    var contentFilters: ContentFilters {
        get { (try? JSONDecoder().decode(ContentFilters.self, from: contentFiltersData)) ?? .defaults }
        set { contentFiltersData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var reminders: ReminderSettings {
        get { (try? JSONDecoder().decode(ReminderSettings.self, from: remindersData)) ?? .defaults }
        set { remindersData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    // voiceData kept for schema compatibility (unused since listen feature removal)
}
