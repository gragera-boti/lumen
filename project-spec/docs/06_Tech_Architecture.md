# 06 — Technical Architecture (iOS-first)

## 1) Overview

Lumen is an **offline-first** mobile app. The core app does not require a backend. Optional services (content updates, sync, remote config) can be added without changing the user experience.

### 1.1 High-level architecture goals
- **Local-first:** everything works with bundled content.
- **Predictable state:** testable, deterministic feed generation.
- **Privacy-first:** personalization computed on device.
- **Modular:** Widgets/Watch share models and storage.

---

## 2) Proposed stack (iOS MVP)

### 2.1 Language & UI
- Swift 5.9+
- SwiftUI + Swift Concurrency (async/await)
- Combine only where needed for bridging

### 2.2 Persistence
Option A (recommended): SQLite + GRDB  
Option B: Core Data (acceptable)  
Requirements:
- Fast reads for feed
- Easy migrations
- Shared access for Widget extension

### 2.3 Notifications
- UserNotifications framework (UNUserNotificationCenter)
- Local notification scheduling (no server required)

### 2.4 Text-to-speech
- AVFoundation (AVSpeechSynthesizer)

### 2.5 On-device image generation
- Core ML + Apple `ml-stable-diffusion` Swift package (see ML doc)
- Model stored in app bundle or downloaded on-demand (recommended to reduce app size)

### 2.6 Subscriptions
- StoreKit 2
- Entitlement caching and verification

### 2.7 Analytics
- Minimal event logging layer with pluggable providers:
  - MVP: local event store + optional external provider
- Must support hard opt-out and avoid logging sensitive text.

---

## 3) Build targets
- `LumenApp` (main iOS app)
- `LumenWidgets` (WidgetKit extension)
- `LumenWatch` (watchOS app) — P1
- `LumenShared` (Swift package: models, DB, services) — recommended

---

## 4) Module boundaries (Clean-ish architecture)

### 4.1 Domain layer
Pure Swift types + use cases:
- Entities: `Affirmation`, `Category`, `Theme`, `UserPreferences`, `EntitlementState`
- UseCases:
  - `GetNextAffirmationUseCase`
  - `ToggleFavoriteUseCase`
  - `GenerateShareImageUseCase`
  - `ScheduleRemindersUseCase`
  - `GenerateBackgroundUseCase`

### 4.2 Data layer
- Repositories:
  - `AffirmationRepository`
  - `UserPreferencesRepository`
  - `ThemeRepository`
- Local DB adapters
- Content pack loader + migrator

### 4.3 Services layer
- `NotificationScheduler`
- `SpeechService`
- `ImageRenderer` (card → PNG)
- `EntitlementService`
- `AnalyticsService`
- `MLBackgroundService`

### 4.4 UI layer
SwiftUI Views + ViewModels (Observable):
- `OnboardingViewModel`
- `FeedViewModel`
- `FavoritesViewModel`
- `SettingsViewModel`
- `ThemeGeneratorViewModel`

---

## 5) Data flow (simplified)

1) App loads bundled content pack JSON on first run.
2) Content imported into local DB tables.
3) Feed requests “next card” via `GetNextAffirmationUseCase`.
4) Card uses `ThemeRepository` to resolve background:
   - curated image/gradient, or generated background.
5) Actions update repositories and log analytics events.

---

## 6) Storage & shared access for Widgets

Widgets must access:
- `AffirmationOfTheDay`
- current theme
- a small curated set of recent affirmations

Best practice:
- Use App Group container for shared DB file.
- Provide a “WidgetDataStore” that writes small JSON snapshots for WidgetKit to read quickly.

---

## 7) Error handling strategy
- Prefer “fail open” for content: if generation fails, show curated theme.
- Never crash on malformed content pack; validate and rollback.
- Background generation errors are user-facing (“Couldn’t generate — try again”).

---

## 8) Observability
- Crash reporting optional; if enabled, ensure privacy compliance.
- Key performance counters:
  - time_to_first_card_ms
  - share_render_time_ms
  - generation_time_ms
  - reminder_schedule_success_rate

---

## 9) Mermaid architecture diagram
See `assets/diagrams/architecture.mermaid`.
