# 02 — Functional Requirements (FR) & Non-Functional Requirements (NFR)

This document is **the source of truth** for engineering scope. Each requirement has:
- **Priority:** P0 (MVP), P1 (v1), P2 (later)
- **Acceptance Criteria:** testable outcomes
- **Notes:** implementation hints / edge cases

---

## 0. Conventions
- “User” means an end-user on a device.
- “Affirmation card” means the UI unit showing a background + affirmation text.
- “Content pack” means a versioned bundle of categories + affirmations, shipped with app and/or downloaded.

---

# 1) Onboarding & first run

### FR-1.1 — First-run welcome and wellness disclaimer
**Priority:** P0  
**Description:** On first launch, show a welcome screen that communicates the app is for wellness and not medical care.  
**Acceptance Criteria:**
- Welcome appears only when `hasCompletedOnboarding=false`.
- Includes “not a substitute for professional care” message and a link to “Get help now”.
- User can continue without creating an account.

### FR-1.2 — Category selection
**Priority:** P0  
**Description:** User selects 1+ categories/goals to personalize the feed (e.g., Self-love, Confidence, Calm).  
**Acceptance Criteria:**
- Multi-select UI; minimum 1 selection enforced.
- Selection stored locally in `UserPreferences.selectedCategoryIds`.
- User can edit later in Settings.

### FR-1.3 — Tone selection
**Priority:** P0  
**Description:** User chooses default tone: `Gentle`, `Neutral`, `Energetic`, optionally `Spiritual`.  
**Acceptance Criteria:**
- Tone stored in `UserPreferences.tonePreset`.
- Tone influences content selection (see FR-2.6).

### FR-1.4 — Reminders setup + permission request
**Priority:** P0  
**Description:** Onboarding asks how many reminders/day and preferred time window; then requests notification permission.  
**Acceptance Criteria:**
- If user declines permission, onboarding still completes and reminders UI indicates disabled state.
- Permission request appears only after user has expressed intent (Apple best practice).
- Reminder settings stored locally; can be changed later.

### FR-1.5 — Optional mood baseline (soft)
**Priority:** P1  
**Description:** Optional question “How are you feeling lately?” with choices (Good/Okay/Low/Prefer not to say).  
**Acceptance Criteria:**
- If “Low”, app defaults to “gentle/realistic” content filtering (see FR-2.7).
- Data stays local by default.

---

# 2) Core content experience

### FR-2.1 — Swipeable affirmation feed
**Priority:** P0  
**Description:** Main screen shows an affirmation card; user can swipe vertically to next.  
**Acceptance Criteria:**
- First card loads in < 1s on mid device (excluding first launch asset install).
- Feed supports infinite scroll of generated sequence.
- Cards are cached to allow back navigation for last N=50 items.

### FR-2.2 — Card actions: like/favorite
**Priority:** P0  
**Description:** User can favorite an affirmation.  
**Acceptance Criteria:**
- Favorite toggles immediately and persists across app restarts.
- Favorited affirmations appear in Favorites screen (FR-4.1).
- If content pack updates, favorites map by stable `affirmationId`.

### FR-2.3 — Card actions: share image
**Priority:** P0  
**Description:** User can share the card as an image (background + text).  
**Acceptance Criteria:**
- Share sheet includes Messages, social apps, “Save Image” (if supported).
- Export image includes safe margins and respects dynamic type.
- If user enabled watermark off (premium), no watermark; else a small brand mark appears.

### FR-2.4 — Card actions: text-to-speech (TTS)
**Priority:** P0  
**Description:** User can tap “Play” to hear the affirmation read aloud.  
**Acceptance Criteria:**
- Uses system TTS voice (AVSpeechSynthesizer on iOS).
- Settings allow voice/language selection (FR-6.3).
- Playback controls: play/pause/stop; no overlapping audio.

### FR-2.5 — “For You” vs “Explore”
**Priority:** P0  
**Description:** App includes two primary modes:
- **For You:** personalized feed based on selected categories.
- **Explore:** browse categories and play a category-specific feed.
**Acceptance Criteria:**
- Tab bar or segmented control switches modes.
- Explore shows a category grid; tapping category opens its feed.

### FR-2.6 — Content ranking (baseline)
**Priority:** P0  
**Description:** The app selects the next affirmation using a deterministic-but-varied algorithm, influenced by:
- selected categories
- tone preset
- prior likes/dislikes
- recency (avoid repeats)
**Acceptance Criteria:**
- No immediate repeats within last N=50 shown cards.
- Likes increase probability of similar tags/categories.
- Dislikes (FR-2.8) reduce probability.

### FR-2.7 — “Gentle mode” content filter
**Priority:** P0  
**Description:** Provide a mode that avoids high-intensity/overly absolute statements. Default ON for low mood baseline; user can toggle anytime.  
**Acceptance Criteria:**
- When enabled, app excludes affirmations tagged `intensity=HIGH` or `absolute=true`.
- When disabled, full library is available (still respecting safety constraints).
- Mode is visible in Settings + optionally as quick toggle on feed.

### FR-2.8 — Dislike / “Not for me”
**Priority:** P1  
**Description:** User can mark an affirmation as not helpful.  
**Acceptance Criteria:**
- Disliked content is suppressed for >= 90 days.
- If user selects reason (optional), it is stored locally.
- Dislike is available from card overflow menu.

### FR-2.9 — Daily “Affirmation of the Day”
**Priority:** P0  
**Description:** App selects one daily highlight affirmation.  
**Acceptance Criteria:**
- Same highlight shown in widget + main screen header (optional).
- Rotates once per local day, but user can still browse feed.

### FR-2.10 — History
**Priority:** P0  
**Description:** User can view recently seen affirmations (read-only).  
**Acceptance Criteria:**
- Shows last N=200 viewed items.
- Supports search by text (P1).

---

# 3) Categories & content packs

### FR-3.1 — Category model
**Priority:** P0  
**Description:** Categories have id, localized name, description, icon, premium flag.  
**Acceptance Criteria:**
- Categories are loaded from bundled content pack at install.
- Category list is localized (en-GB for MVP; more later).

### FR-3.2 — Content pack versioning & updates
**Priority:** P1  
**Description:** App can download updated content packs from backend (optional).  
**Acceptance Criteria:**
- If no network or backend disabled, app functions fully with bundled pack.
- New pack validates signature/hash before install.
- Migration preserves favorites/history referencing old IDs.

### FR-3.3 — Custom user affirmations
**Priority:** P0  
**Description:** User can write and save custom affirmations.  
**Acceptance Criteria:**
- Create/edit/delete custom affirmation.
- Custom affirmations can be included in feed (toggle).
- Custom affirmations are excluded from any cloud sharing by default.

---

# 4) Favorites, Collections, and Library

### FR-4.1 — Favorites list
**Priority:** P0  
**Description:** A screen lists favorite affirmations with search/filter.  
**Acceptance Criteria:**
- Shows background thumbnail + text snippet.
- Tapping opens affirmation detail view.

### FR-4.2 — Collections (playlists)
**Priority:** P2  
**Description:** User groups favorites into named collections.  
**Acceptance Criteria:**
- Create collection, add/remove items, reorder.

---

# 5) Backgrounds, Themes, and On-device generation

### FR-5.1 — Theme selection (curated)
**Priority:** P0  
**Description:** App ships with curated themes (images/gradients).  
**Acceptance Criteria:**
- User selects default theme pack.
- Theme applies to cards, widgets, share images.

### FR-5.2 — On-device background generation (restricted prompts)
**Priority:** P0  
**Description:** User generates backgrounds on-device using diffusion via Core ML (iOS).  
**Acceptance Criteria:**
- User chooses from **predefined styles** and **adjective sliders** (no free-form prompt in MVP).
- Generation runs locally; no image is uploaded by default.
- Generated image saved to local “My Themes”.
- User can delete generated images (and model cache remains).

### FR-5.3 — Generation safety checks
**Priority:** P0  
**Description:** Generated images must be constrained to safe content.  
**Acceptance Criteria:**
- Only app-defined prompt templates used.
- Negative prompts applied to reduce risk (e.g., “people, nude, explicit, violence”).
- Optional on-device safety classifier (P1) blocks unsafe outputs.
- Provide “Report image” action (required for Google Play AI policy compliance if shipping on Android).

### FR-5.4 — Background generation performance & cancellation
**Priority:** P0  
**Description:** Generation shows progress and can be cancelled.  
**Acceptance Criteria:**
- User can cancel; partial output discarded.
- On supported devices, 512×512 image generates within defined budget (see NFR-Perf-2).

### FR-5.5 — Text readability overlay
**Priority:** P0  
**Description:** Ensure affirmation text remains readable over any background.  
**Acceptance Criteria:**
- Automatic contrast: apply gradient overlay or blur behind text if needed.
- Must meet WCAG AA contrast guidelines for typical sizes where feasible.

---

# 6) Settings & personalization controls

### FR-6.1 — Reminder scheduling UI
**Priority:** P0  
**Description:** Settings screen to set frequency and quiet hours.  
**Acceptance Criteria:**
- “Reminders per day” (0–12)
- Time window start/end
- Quiet hours (Do Not Disturb inside app)
- Test notification button.

### FR-6.2 — Content filters
**Priority:** P0  
**Description:** User can toggle optional content dimensions.  
**Acceptance Criteria:**
- Spiritual content (on/off)
- Manifestation language (on/off)
- Body/fitness content (on/off)
- Sensitive topics: grief/illness (opt-in to include)
- “Gentle mode” toggle (FR-2.7)

### FR-6.3 — Voice settings
**Priority:** P0  
**Description:** Choose voice/language/rate for TTS.  
**Acceptance Criteria:**
- Rate (0.5×–1.5×)
- Select from system voices available for selected language.

### FR-6.4 — Data controls
**Priority:** P0  
**Description:** Allow user to export/delete local data.  
**Acceptance Criteria:**
- Export favorites/custom affirmations as JSON.
- “Delete all data” resets to onboarding.

### FR-6.5 — Help & crisis resources
**Priority:** P0  
**Description:** Provide a clear “Get help now” screen and safety messaging.  
**Acceptance Criteria:**
- Accessible from onboarding and Settings.
- Includes guidance to contact local emergency number and professional resources.
- No geolocation required; optionally allow locale selection.

---

# 7) Widgets, Watch, and OS integrations

### FR-7.1 — iOS Widgets
**Priority:** P0  
**Description:** Provide small/medium/large widgets showing a selected affirmation.  
**Acceptance Criteria:**
- Widget reflects selected categories and gentle mode.
- Refresh policy respects OS limits; uses timeline entries.

### FR-7.2 — Deep linking
**Priority:** P0  
**Description:** Tapping a widget/notification deep-links into the corresponding affirmation.  
**Acceptance Criteria:**
- If affirmation no longer available, deep-link falls back to “Affirmation of the Day”.

### FR-7.3 — Apple Watch app
**Priority:** P1  
**Description:** Watch app shows current affirmation and allows next/favorite.  
**Acceptance Criteria:**
- Works offline using shared storage.
- Complication shows short affirmation snippet.

---

# 8) Monetization

### FR-8.1 — Paywall
**Priority:** P0  
**Description:** App includes paywall with subscription options and restore purchases.  
**Acceptance Criteria:**
- Plans: Monthly, Yearly, Lifetime (configurable).
- Shows trial terms if trial enabled.
- Restore purchases button works.
- Paywall respects Apple/Google policy wording.

### FR-8.2 — Entitlements & feature gating
**Priority:** P0  
**Description:** Premium features gated behind entitlement.  
**Premium includes:**
- All categories
- Unlimited on-device generation
- Watermark removal
- More themes
- Advanced reminders (smart timing) (P1)
**Acceptance Criteria:**
- Entitlement state cached locally and updated on app start + purchase events.

### FR-8.3 — Trial flow
**Priority:** P0  
**Description:** Support free trial where applicable.  
**Acceptance Criteria:**
- If user is in trial, premium is enabled.
- UI shows trial end date in Subscription settings.

---

# 9) Analytics & experimentation

### FR-9.1 — Event logging
**Priority:** P0  
**Description:** Log core events to analytics with privacy-first defaults.  
**Acceptance Criteria:**
- No collection of custom affirmation text.
- Can disable analytics (opt-out) in Settings if required by product decision.

### FR-9.2 — Experiment framework
**Priority:** P1  
**Description:** Support remote-config A/B tests (e.g., paywall variants).  
**Acceptance Criteria:**
- Experiments are deterministic per device, persisted locally.
- Provide kill-switch for high-risk features.

---

# 10) Optional cloud sync (post-MVP)

### FR-10.1 — Account optionality
**Priority:** P1  
**Description:** Cloud sync only if user opts in.  
**Acceptance Criteria:**
- Without account, all features still work locally (except multi-device sync).

### FR-10.2 — Sync data
**Priority:** P1  
**Description:** Sync favorites, custom affirmations, themes, settings.  
**Acceptance Criteria:**
- Conflict resolution deterministic (last-write-wins + per-field merge).
- Sync is end-to-end encrypted (P2) or at minimum encrypted in transit + at rest.

---

# NFR — Non-Functional Requirements

## NFR-Sec-1 — Data minimization
- Store only what’s needed.
- Do not upload affirmation interaction history by default.

## NFR-Sec-2 — Encryption
- iOS: Sensitive local data (custom affirmations, preferences) stored encrypted-at-rest where feasible (Keychain for tokens; DB encryption optional).
- Network: TLS 1.2+; certificate pinning optional.

## NFR-Perf-1 — App startup
- Cold start to first card render < 1.0s on mid-tier device (without model loading).
- Warm start < 300ms.

## NFR-Perf-2 — ML generation
- Target: 512×512 image in <= 12 seconds on supported devices (A16+).
- If slower, UI must show progress and allow cancel; recommend lower steps on slow devices.

## NFR-Avail-1 — Offline-first
- Full core experience works offline after first install.
- Content pack downloads are additive, not required.

## NFR-Acc-1 — Accessibility
- Support Dynamic Type.
- VoiceOver labels for all actionable elements.
- Reduce Motion support.
- High contrast mode tested.

## NFR-L10n-1 — Localization
- All strings via localization tables.
- Content packs support locale variants (en-GB vs en-US).
- RTL not required for MVP but do not hard-code layout.

## NFR-Qual-1 — Test coverage
- Core algorithm/data layer unit coverage ≥ 70%.
- UI tests for onboarding, reminders, favorite, share.

## NFR-Policy-1 — App store compliance
- Comply with Apple App Review Guidelines and Google Play AI-Generated Content policies (if Android build includes generation).
- Provide in-app reporting for AI-generated content where applicable.
