# Lumen — Documentation

## Overview

Lumen is an iOS affirmation & wellness app built with SwiftUI and SwiftData. It delivers personalized affirmations with beautiful backgrounds, mood tracking, and AI-generated themes.

**Deployment Target:** iOS 26.0+  
**Architecture:** MVVM + Services  
**Persistence:** SwiftData  
**Monetization:** RevenueCat (freemium)

---

## Architecture

```
View (@State var vm) → ViewModel (@Observable) → Service (protocol) → SwiftData / Network
     ↑ bindings via @Bindable                        ↑ injected via init
```

### Layers

| Layer | Responsibility |
|-------|---------------|
| **View** | Declarative UI, layout, styling. No business logic. |
| **ViewModel** | `@MainActor @Observable final class`. Presentation logic, state management. |
| **Service** | Protocol-defined. Data access, persistence, networking. Injected into ViewModels. |

### Navigation

Centralized `AppRouter` (`@Observable`) with per-tab `NavigationPath` instances. Views call `router.navigate(to:in:)`. Destinations defined in `AppDestination` enum.

---

## Features

### Feed (`Features/Feed/`)
- Full-screen affirmation cards with crossfade transitions
- Background images (AI-generated, procedural, or gradient fallback)
- Mood check-in overlay adapts feed content to current mood
- Tap zones (left/right) and swipe navigation
- Favorite and share actions per card
- Custom affirmation creation with font picker and ML-powered suggestions

### Favorites (`Features/Favorites/`)
- List of user-created and curated favorite affirmations
- Slideshow mode with auto-advance timer
- Edit and delete user-created affirmations
- Swipe actions for quick management

### Explore (`Features/Explore/`)
- Category grid with premium gating
- Category-specific affirmation feed (same card UX as main feed)

### History (`Features/History/`)
- Chronological list of recently viewed affirmations
- Tap to view detail

### Onboarding (`Features/Onboarding/`)
- Multi-step flow: Welcome → Categories → Tone → Reminders
- Category and tone selection saved to UserPreferences
- Notification permission request

### Settings (`Features/Settings/`)
- Content filters (spiritual, manifestation, body focus, sensitive topics)
- Reminder scheduling with quiet hours
- Theme management and generation
- Subscription management
- Privacy/data export
- History access

### Paywall (`Features/Paywall/`)
- RevenueCat PaywallView wrapper

### Crisis Support (`Features/Crisis/`)
- Emergency contact links and international helplines
- Always accessible from Settings

### Theme Generator (`Features/ThemeGenerator/`)
- **Procedural mode:** Instant Core Graphics backgrounds with style, palette, mood, complexity controls
- **AI mode:** On-device Stable Diffusion via Core ML with prompt categories, pre-generation, and caching

### Affirmation Detail (`Features/AffirmationDetail/`)
- Full-screen gradient view with favorite toggle and share

---

## Navigation Destinations

```swift
enum AppDestination: Hashable {
    case categoryFeed(categoryId: String)
    case affirmationDetail(affirmationId: String)
    case reminders
    case themes
    case contentFilterSettings
    case subscription
    case privacyData
    case crisis
    case themeGenerator
    case themeGallery
    case history
}
```

**Tabs:** For You, Explore, Favorites, Settings

---

## Models

| Model | Purpose |
|-------|---------|
| `Affirmation` | Core content — text, tone, intensity, source, font style |
| `Category` | Grouping with icon, premium flag, sensitivity flag |
| `Favorite` | Join model linking affirmation to favorites list |
| `SeenEvent` | Tracks when/where an affirmation was viewed |
| `Dislike` | Tracks disliked affirmations for filtering |
| `MoodEntry` | Daily mood check-in record |
| `UserPreferences` | Tone, filters, reminders, analytics opt-out |
| `AppTheme` | Saved background themes (generated or AI) |
| `EntitlementState` | Cached premium status |

---

## Service Protocols

| Protocol | Responsibility |
|----------|---------------|
| `FeedServiceProtocol` | Load affirmation batches, daily affirmation, record seen events |
| `FavoriteServiceProtocol` | Toggle favorites, fetch favorite list |
| `ContentServiceProtocol` | Load bundled content, fetch categories and affirmations |
| `PreferencesServiceProtocol` | Get/create and save UserPreferences |
| `MoodServiceProtocol` | Record mood, fetch today's and recent moods |
| `EntitlementServiceProtocol` | Check premium status, purchase, restore |
| `NotificationServiceProtocol` | Request permission, schedule/cancel reminders |
| `ShareServiceProtocol` | Render share images with gradient + text |
| `DislikeServiceProtocol` | Dislike/undislike affirmations |
| `WidgetServiceProtocol` | Update widget data in App Group container |
| `AIBackgroundServiceProtocol` | On-device AI image generation via Core ML |
| `BackgroundGeneratorProtocol` | Procedural background generation via Core Graphics |
| `AnalyticsServiceProtocol` | Privacy-first event logging with opt-out |
| `CloudSyncServiceProtocol` | iCloud sync (premium) — enable/disable, status |

---

## Data Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐     ┌────────────┐
│   SwiftUI   │────▶│  ViewModel   │────▶│    Service       │────▶│  SwiftData │
│    View     │     │ (@Observable)│     │  (Protocol)      │     │   Store    │
│             │◀────│              │◀────│                  │◀────│            │
└─────────────┘     └──────────────┘     └─────────────────┘     └────────────┘
       │                                         │
       │                                         ├──▶ RevenueCat (Entitlements)
       │                                         ├──▶ Core ML (AI Backgrounds)
       │                                         ├──▶ UNNotificationCenter
       │                                         └──▶ WidgetKit (App Group)
       │
       └──▶ AppRouter (NavigationPath per tab)
```

---

## Extensions

| File | Purpose |
|------|---------|
| `Color+Hex.swift` | Initialize Color from hex string |
| `Date+Formatting.swift` | Date formatting helpers |
| `String+Localization.swift` | `.localized` convenience |
| `Logger+Lumen.swift` | Centralized OSLog categories |

---

## Widgets

`LumenWidgets/` — Home screen widget showing daily affirmation with gradient background. Data shared via App Group container (`group.com.gragera.lumen`).
