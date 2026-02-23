// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
// Generated using tuist — https://github.com/tuist/tuist

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
public enum LumenStrings: Sendable {
  /// Share
  public static let share = LumenStrings.tr("Localizable", "share")

  public enum Affirmation: Sendable {
  /// Affirmation not found
    public static let notFound = LumenStrings.tr("Localizable", "affirmation.notFound")
  }

  public enum App: Sendable {
  /// Lumen
    public static let name = LumenStrings.tr("Localizable", "app.name")
  }

  public enum Crisis: Sendable {
  /// Befrienders Worldwide
    public static let befrienders = LumenStrings.tr("Localizable", "crisis.befrienders")
    /// Emotional support worldwide
    public static let befriendersSubtitle = LumenStrings.tr("Localizable", "crisis.befriendersSubtitle")
    /// If you or someone you know is in crisis or feeling unsafe, please reach out for help.
    public static let body = LumenStrings.tr("Localizable", "crisis.body")
    /// I'm not in crisis
    public static let dismiss = LumenStrings.tr("Localizable", "crisis.dismiss")
    /// Emergency Services
    public static let emergency = LumenStrings.tr("Localizable", "crisis.emergency")
    /// Call your local emergency number (112, 911, 999)
    public static let emergencySubtitle = LumenStrings.tr("Localizable", "crisis.emergencySubtitle")
    /// You're not alone
    public static let headline = LumenStrings.tr("Localizable", "crisis.headline")
    /// International Association for Suicide Prevention
    public static let iasp = LumenStrings.tr("Localizable", "crisis.iasp")
    /// Find a crisis centre near you
    public static let iaspSubtitle = LumenStrings.tr("Localizable", "crisis.iaspSubtitle")
    /// Crisis Text Line
    public static let textLine = LumenStrings.tr("Localizable", "crisis.textLine")
    /// Text HOME to 741741 (US)
    public static let textLineSubtitle = LumenStrings.tr("Localizable", "crisis.textLineSubtitle")
    /// Get Help
    public static let title = LumenStrings.tr("Localizable", "crisis.title")
  }

  public enum Custom: Sendable {
  /// Cancel
    public static let cancel = LumenStrings.tr("Localizable", "custom.cancel")
    /// Write something kind for yourself…
    public static let placeholder = LumenStrings.tr("Localizable", "custom.placeholder")
    /// Save
    public static let save = LumenStrings.tr("Localizable", "custom.save")
    /// New Affirmation
    public static let title = LumenStrings.tr("Localizable", "custom.title")
    /// Tone
    public static let tone = LumenStrings.tr("Localizable", "custom.tone")
    /// Keep it under 200 characters.
    public static let tooLong = LumenStrings.tr("Localizable", "custom.tooLong")
  }

  public enum Explore: Sendable {
  /// Premium
    public static let premium = LumenStrings.tr("Localizable", "explore.premium")
    /// Explore
    public static let title = LumenStrings.tr("Localizable", "explore.title")
  }

  public enum Favorites: Sendable {
  /// Favorite
    public static let add = LumenStrings.tr("Localizable", "favorites.add")
    /// Remove
    public static let remove = LumenStrings.tr("Localizable", "favorites.remove")
    /// Favorites
    public static let title = LumenStrings.tr("Localizable", "favorites.title")

    public enum Empty: Sendable {
    /// Tap the heart on any affirmation to save it here.
      public static let description = LumenStrings.tr("Localizable", "favorites.empty.description")
      /// No favorites yet
      public static let title = LumenStrings.tr("Localizable", "favorites.empty.title")
    }
  }

  public enum Feed: Sendable {
  /// Create custom affirmation
    public static let createCustom = LumenStrings.tr("Localizable", "feed.createCustom")
    /// Edit
    public static let edit = LumenStrings.tr("Localizable", "feed.edit")
    /// Favorite
    public static let favorite = LumenStrings.tr("Localizable", "feed.favorite")
    /// Listen
    public static let listen = LumenStrings.tr("Localizable", "feed.listen")
    /// Pause
    public static let pause = LumenStrings.tr("Localizable", "feed.pause")
    /// Share
    public static let share = LumenStrings.tr("Localizable", "feed.share")

    public enum Empty: Sendable {
    /// Try adding more categories or turning off Gentle mode.
      public static let description = LumenStrings.tr("Localizable", "feed.empty.description")
      /// No affirmations match your filters
      public static let title = LumenStrings.tr("Localizable", "feed.empty.title")
    }
  }

  public enum Filters: Sendable {
  /// Body & fitness
    public static let bodyFocus = LumenStrings.tr("Localizable", "filters.bodyFocus")
    /// Content types
    public static let contentTypes = LumenStrings.tr("Localizable", "filters.contentTypes")
    /// Toggle which content types appear in your feed.
    public static let contentTypesFooter = LumenStrings.tr("Localizable", "filters.contentTypesFooter")
    /// Gentle mode
    public static let gentleMode = LumenStrings.tr("Localizable", "filters.gentleMode")
    /// Gentle mode hides intense or absolute statements like "I am unstoppable".
    public static let gentleModeDescription = LumenStrings.tr("Localizable", "filters.gentleModeDescription")
    /// Include sensitive topics (grief, illness)
    public static let includeSensitive = LumenStrings.tr("Localizable", "filters.includeSensitive")
    /// Intensity
    public static let intensity = LumenStrings.tr("Localizable", "filters.intensity")
    /// Manifestation language
    public static let manifestation = LumenStrings.tr("Localizable", "filters.manifestation")
    /// These topics are hidden by default to avoid unexpected content.
    public static let sensitiveFooter = LumenStrings.tr("Localizable", "filters.sensitiveFooter")
    /// Sensitive topics
    public static let sensitiveTopics = LumenStrings.tr("Localizable", "filters.sensitiveTopics")
    /// Spiritual content
    public static let spiritual = LumenStrings.tr("Localizable", "filters.spiritual")
    /// Content Filters
    public static let title = LumenStrings.tr("Localizable", "filters.title")
  }

  public enum General: Sendable {
  /// Cancel
    public static let cancel = LumenStrings.tr("Localizable", "general.cancel")
    /// Close
    public static let close = LumenStrings.tr("Localizable", "general.close")
    /// Delete
    public static let delete = LumenStrings.tr("Localizable", "general.delete")
    /// Error
    public static let error = LumenStrings.tr("Localizable", "general.error")
    /// OK
    public static let ok = LumenStrings.tr("Localizable", "general.ok")
    /// Privacy
    public static let privacy = LumenStrings.tr("Localizable", "general.privacy")
    /// Terms
    public static let terms = LumenStrings.tr("Localizable", "general.terms")
  }

  public enum Generator: Sendable {
  /// Color
    public static let color = LumenStrings.tr("Localizable", "generator.color")
    /// Detail level
    public static let detail = LumenStrings.tr("Localizable", "generator.detail")
    /// Images are generated on your device.
    public static let footer = LumenStrings.tr("Localizable", "generator.footer")
    /// Generate
    public static let generate = LumenStrings.tr("Localizable", "generator.generate")
    /// Generating…
    public static let generating = LumenStrings.tr("Localizable", "generator.generating")
    /// Mood
    public static let mood = LumenStrings.tr("Localizable", "generator.mood")
    /// Style
    public static let style = LumenStrings.tr("Localizable", "generator.style")
    /// Generate Background
    public static let title = LumenStrings.tr("Localizable", "generator.title")
  }

  public enum History: Sendable {
  /// History
    public static let title = LumenStrings.tr("Localizable", "history.title")

    public enum Empty: Sendable {
    /// Affirmations you view will appear here.
      public static let description = LumenStrings.tr("Localizable", "history.empty.description")
      /// No history yet
      public static let title = LumenStrings.tr("Localizable", "history.empty.title")
    }
  }

  public enum Mood: Sendable {
  /// How are you feeling today?
    public static let prompt = LumenStrings.tr("Localizable", "mood.prompt")
  }

  public enum Onboarding: Sendable {

    public enum Categories: Sendable {
    /// Sensitive topics (opt-in)
      public static let sensitive = LumenStrings.tr("Localizable", "onboarding.categories.sensitive")
      /// Pick at least one
      public static let subtitle = LumenStrings.tr("Localizable", "onboarding.categories.subtitle")
      /// Choose what you want more of
      public static let title = LumenStrings.tr("Localizable", "onboarding.categories.title")
    }

    public enum Reminders: Sendable {
    /// Enable reminders
      public static let enable = LumenStrings.tr("Localizable", "onboarding.reminders.enable")
      /// Not now
      public static let notNow = LumenStrings.tr("Localizable", "onboarding.reminders.notNow")
      /// Reminders per day: %d
      public static func perDay(_ p1: Int) -> String {
        return LumenStrings.tr("Localizable", "onboarding.reminders.perDay",p1)
      }
      /// Set your reminders
      public static let title = LumenStrings.tr("Localizable", "onboarding.reminders.title")
    }

    public enum Tone: Sendable {
    /// Choose your tone
      public static let title = LumenStrings.tr("Localizable", "onboarding.tone.title")
    }

    public enum Welcome: Sendable {
    /// Continue
      public static let continueButton = LumenStrings.tr("Localizable", "onboarding.welcome.continueButton")
      /// This app is for wellness, not medical care. If you feel unsafe or in crisis, tap below.
      public static let disclaimer = LumenStrings.tr("Localizable", "onboarding.welcome.disclaimer")
      /// Lumen
      public static let headline = LumenStrings.tr("Localizable", "onboarding.welcome.headline")
      /// Get help now
      public static let helpButton = LumenStrings.tr("Localizable", "onboarding.welcome.helpButton")
      /// Daily affirmations that feel kind — not forced.
      public static let subtitle = LumenStrings.tr("Localizable", "onboarding.welcome.subtitle")
    }
  }

  public enum Paywall: Sendable {
  /// Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is cancelled at least 24 hours before the end of the current period.
    public static let legal = LumenStrings.tr("Localizable", "paywall.legal")
    /// Restore Purchases
    public static let restore = LumenStrings.tr("Localizable", "paywall.restore")
    /// Unlock Lumen Premium
    public static let title = LumenStrings.tr("Localizable", "paywall.title")

    public enum Feature: Sendable {
    /// All categories and content
      public static let categories = LumenStrings.tr("Localizable", "paywall.feature.categories")
      /// Unlimited background generation
      public static let generation = LumenStrings.tr("Localizable", "paywall.feature.generation")
      /// Premium themes
      public static let themes = LumenStrings.tr("Localizable", "paywall.feature.themes")
      /// Remove watermarks
      public static let watermark = LumenStrings.tr("Localizable", "paywall.feature.watermark")
    }
  }

  public enum Reminders: Sendable {
  /// Disabled
    public static let disabled = LumenStrings.tr("Localizable", "reminders.disabled")
    /// Enabled
    public static let enabled = LumenStrings.tr("Localizable", "reminders.enabled")
    /// Not set
    public static let notSet = LumenStrings.tr("Localizable", "reminders.notSet")
    /// Reminders per day: %d
    public static func perDay(_ p1: Int) -> String {
      return LumenStrings.tr("Localizable", "reminders.perDay",p1)
    }
    /// Notification permission
    public static let permission = LumenStrings.tr("Localizable", "reminders.permission")
    /// Quiet end
    public static let quietEnd = LumenStrings.tr("Localizable", "reminders.quietEnd")
    /// Quiet start
    public static let quietStart = LumenStrings.tr("Localizable", "reminders.quietStart")
    /// Send test notification
    public static let testButton = LumenStrings.tr("Localizable", "reminders.testButton")
    /// Test sent!
    public static let testSent = LumenStrings.tr("Localizable", "reminders.testSent")
    /// Reminders
    public static let title = LumenStrings.tr("Localizable", "reminders.title")
    /// Window end
    public static let windowEnd = LumenStrings.tr("Localizable", "reminders.windowEnd")
    /// Window start
    public static let windowStart = LumenStrings.tr("Localizable", "reminders.windowStart")
  }

  public enum Settings: Sendable {
  /// Appearance
    public static let appearance = LumenStrings.tr("Localizable", "settings.appearance")
    /// Content
    public static let content = LumenStrings.tr("Localizable", "settings.content")
    /// Content Filters
    public static let contentFilters = LumenStrings.tr("Localizable", "settings.contentFilters")
    /// Data & Privacy
    public static let dataPrivacy = LumenStrings.tr("Localizable", "settings.dataPrivacy")
    /// Delete All Data
    public static let deleteAll = LumenStrings.tr("Localizable", "settings.deleteAll")
    /// Gentle Mode
    public static let gentleMode = LumenStrings.tr("Localizable", "settings.gentleMode")
    /// Get help now
    public static let getHelp = LumenStrings.tr("Localizable", "settings.getHelp")
    /// Help
    public static let help = LumenStrings.tr("Localizable", "settings.help")
    /// History
    public static let history = LumenStrings.tr("Localizable", "settings.history")
    /// Manage Subscription
    public static let manageSubscription = LumenStrings.tr("Localizable", "settings.manageSubscription")
    /// Premium
    public static let premium = LumenStrings.tr("Localizable", "settings.premium")
    /// Privacy & Data
    public static let privacyData = LumenStrings.tr("Localizable", "settings.privacyData")
    /// Recently Viewed
    public static let recentlyViewed = LumenStrings.tr("Localizable", "settings.recentlyViewed")
    /// Reminders
    public static let reminders = LumenStrings.tr("Localizable", "settings.reminders")
    /// Reminder Schedule
    public static let reminderSchedule = LumenStrings.tr("Localizable", "settings.reminderSchedule")
    /// Subscription
    public static let subscription = LumenStrings.tr("Localizable", "settings.subscription")
    /// Themes & Backgrounds
    public static let themes = LumenStrings.tr("Localizable", "settings.themes")
    /// Settings
    public static let title = LumenStrings.tr("Localizable", "settings.title")
    /// Tone
    public static let tone = LumenStrings.tr("Localizable", "settings.tone")
    /// Voice
    public static let voice = LumenStrings.tr("Localizable", "settings.voice")
    /// Voice Settings
    public static let voiceSettings = LumenStrings.tr("Localizable", "settings.voiceSettings")

    public enum DeleteConfirm: Sendable {
    /// This will reset the app to its initial state. This cannot be undone.
      public static let message = LumenStrings.tr("Localizable", "settings.deleteConfirm.message")
      /// Delete all data?
      public static let title = LumenStrings.tr("Localizable", "settings.deleteConfirm.title")
    }
  }

  public enum Subscription: Sendable {
  /// Contact Support
    public static let contactSupport = LumenStrings.tr("Localizable", "subscription.contact_support")
    /// Current plan
    public static let currentPlan = LumenStrings.tr("Localizable", "subscription.current_plan")
    /// Manage Subscription
    public static let manage = LumenStrings.tr("Localizable", "subscription.manage")
    /// Restore Purchases
    public static let restore = LumenStrings.tr("Localizable", "subscription.restore")

    public enum Plan: Sendable {
    /// Free
      public static let free = LumenStrings.tr("Localizable", "subscription.plan.free")
      /// Premium
      public static let premium = LumenStrings.tr("Localizable", "subscription.plan.premium")
    }

    public enum Upgrade: Sendable {
    /// Unlock all categories, unlimited themes, and more
      public static let subtitle = LumenStrings.tr("Localizable", "subscription.upgrade.subtitle")
      /// Upgrade to Lumen Pro
      public static let title = LumenStrings.tr("Localizable", "subscription.upgrade.title")
    }
  }

  public enum Tab: Sendable {
  /// Explore
    public static let explore = LumenStrings.tr("Localizable", "tab.explore")
    /// Favorites
    public static let favorites = LumenStrings.tr("Localizable", "tab.favorites")
    /// For You
    public static let forYou = LumenStrings.tr("Localizable", "tab.forYou")
    /// Settings
    public static let settings = LumenStrings.tr("Localizable", "tab.settings")
  }

  public enum Voice: Sendable {
  /// Language
    public static let language = LumenStrings.tr("Localizable", "voice.language")
    /// Preview voice
    public static let preview = LumenStrings.tr("Localizable", "voice.preview")
    /// Rate: %.1f×
    public static func rate(_ p1: Float) -> String {
      return LumenStrings.tr("Localizable", "voice.rate",p1)
    }
    /// Speed
    public static let speed = LumenStrings.tr("Localizable", "voice.speed")
    /// Voice
    public static let title = LumenStrings.tr("Localizable", "voice.title")

    public enum Quality: Sendable {
    /// Standard Voices
      public static let `default` = LumenStrings.tr("Localizable", "voice.quality.default")
      /// Enhanced Voices
      public static let enhanced = LumenStrings.tr("Localizable", "voice.quality.enhanced")
      /// Premium Voices
      public static let premium = LumenStrings.tr("Localizable", "voice.quality.premium")

      public enum Enhanced: Sendable {
      /// May need to download in Settings → Accessibility → Spoken Content
        public static let description = LumenStrings.tr("Localizable", "voice.quality.enhanced.description")
      }

      public enum Premium: Sendable {
      /// Highest quality — natural and expressive
        public static let description = LumenStrings.tr("Localizable", "voice.quality.premium.description")
      }
    }

    public enum Speed: Sendable {
    /// Brisk
      public static let brisk = LumenStrings.tr("Localizable", "voice.speed.brisk")
      /// Fast
      public static let fast = LumenStrings.tr("Localizable", "voice.speed.fast")
      /// Normal
      public static let normal = LumenStrings.tr("Localizable", "voice.speed.normal")
      /// Relaxed
      public static let relaxed = LumenStrings.tr("Localizable", "voice.speed.relaxed")
      /// Slow
      public static let slow = LumenStrings.tr("Localizable", "voice.speed.slow")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension LumenStrings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.module.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
// swiftformat:enable all
// swiftlint:enable all
