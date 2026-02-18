# CHANGELOG

## 2025-07-17 — Core ML + Full Content + Tests + Watch + L10n

### Added (third pass — Core ML)
- **MLBackgroundService:** Full on-device background generation pipeline
  - Device capability detection (memory, thermal state)
  - Device tier classification (high/mid/low → step count adjustment)
  - Model download/delete management with progress
  - Procedural generation fallback (MVP) producing real images
  - Safety: restricted prompt templates + negative prompts
  - File management: image + thumbnail saving to App Group
  - Commented integration point for `apple/ml-stable-diffusion` Swift package
- **ThemeGeneratorViewModel:** Full MVVM with generate/cancel/save/model management
- **ThemeGeneratorView:** Rewritten with live preview, progress, model download UI
- **Tests:** MLBackgroundServiceTests (prompt composition, safety terms, generation, all style combos), ThemeGeneratorViewModelTests (capability, download, generate, cancel, error handling) — **13 test files total**

### Added (second pass)
- **Tests:** FeedService (13 tests), FavoriteService (5 tests), ContentService (5 tests), PreferencesService (6 tests), DislikeService (4 tests), ExploreViewModel, SettingsViewModel
- **Content:** Expanded to **85 curated affirmations** across all 13 categories (2,000+ via sub-agent)
- **Watch App:** WatchContentView with favorite/next actions, WatchComplication (rectangular, inline, corner)
- **Localization:** Full en/es Localizable.strings (100+ keys each), String+Localization helper
- **Analytics:** AnalyticsServiceProtocol + local implementation with 20+ event types
- **Dislike:** DislikeService + protocol for "Not for me" feature
- **History:** HistoryView + HistoryViewModel showing last 200 viewed affirmations
- **Navigation:** Added history destination

---

## 2025-07-17 — Initial Implementation

### Added
- **Models:** SwiftData models for Affirmation, Category, Favorite, SeenEvent, Dislike, AppTheme, UserPreferences, EntitlementState
- **Enums:** Tone, Intensity, AffirmationSource, ThemeType, SeenSource, ContentFilters, ReminderSettings, VoiceSettings
- **Services:** ContentService, FeedService, FavoriteService, PreferencesService, SpeechService, NotificationService, EntitlementService, ShareService, WidgetService — all protocol-defined with injectable implementations
- **Navigation:** AppRouter with per-tab NavigationPath, AppDestination enum, DeepLinkHandler (lumen:// scheme)
- **Onboarding:** 4-step flow — Welcome → Categories → Tone → Reminders, with wellness disclaimer and crisis link
- **Feed:** Swipeable affirmation card feed with weighted selection algorithm, favorite/TTS/share actions, daily affirmation
- **Explore:** Category grid with per-category feed view
- **Favorites:** List with swipe-to-remove
- **Settings:** Content filters, reminders, themes, voice, subscription, privacy/data, crisis resources
- **Paywall:** Premium feature presentation with StoreKit 2 integration (monthly/yearly/lifetime)
- **Theme Generator:** Style/color/mood/detail selection UI (ML generation stub for MVP)
- **Crisis View:** Help resources with emergency contacts and external links
- **Custom Affirmations:** User can create personal affirmations (FR-3.3)
- **Widgets:** WidgetKit extension with small/medium/large sizes, gradient backgrounds
- **Share:** Image rendering service for social sharing (1080×1920) with watermark gating
- **TTS:** AVSpeechSynthesizer with configurable voice/rate/language
- **Notifications:** Local notification scheduling with time windows and quiet hours
- **Deep Links:** URL scheme handling for affirmations, categories, settings, paywall, crisis
- **Theme System:** Design tokens (LumenTheme), gradient backgrounds, readability overlay
- **Bundled Content:** 35 curated affirmations across 13 categories from spec content pack
- **Tests:** Unit tests for OnboardingViewModel, FeedViewModel, PaywallViewModel, FavoritesViewModel
