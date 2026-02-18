# 17 — Detailed Screen Specs (UI contract for engineers)

This document expands `docs/03_UX_Flows_and_Wireframes.md` into **implementation-grade** screen contracts:
- UI components
- State
- Actions
- Analytics hooks
- Edge cases

---

## OB-1 Welcome

**Route:** `onboarding/welcome`  
**Entry:** app launch when `hasCompletedOnboarding=false`

### UI components
- `LogoMark`
- `HeadlineText`
- `BodyText`
- `WellnessNoticeText` (with tappable `LearnMoreLink`)
- `PrimaryButton` = “Continue”
- `SecondaryButton` = “Get help now”

### State
- No external dependencies.
- `isShowingCrisisSheet: Bool`

### Actions
- Continue → OB-2
- Get help now → open `Help/Crisis` (modal or push)

### Analytics
- `onboarding_started`

### Edge cases
- If user leaves app and returns, stay on OB-1 until Continue.

---

## OB-2 Category Selection

**Route:** `onboarding/categories`

### Data
- Load categories from local content pack (filtered by locale).
- Split into:
  - core categories
  - sensitive categories (grief/illness) behind opt-in toggles

### UI components
- `CategoryGrid`
- `SensitiveTopicsToggle`
- `ContinueButton` (disabled if 0 core categories selected)

### State
- `selectedCategoryIds: Set<String>`
- `includeSensitiveTopics: Bool`

### Actions
- Toggle category → update state
- Continue → persist preferences and navigate OB-3

### Analytics
- `onboarding_categories_selected` (props: count, includeSensitiveTopics)

### Edge cases
- If content pack fails to load: show retry + fallback built-in list.

---

## OB-3 Tone

**Route:** `onboarding/tone`

### UI components
- `ToneOptionCard` x4
  - Gentle (recommended)
  - Neutral
  - Energetic
  - Spiritual (optional)
- `ContinueButton`

### State
- `tonePreset: TonePreset`

### Actions
- Select tone → update state
- Continue → OB-4

### Analytics
- `onboarding_tone_selected`

---

## OB-4 Reminders Setup

**Route:** `onboarding/reminders`

### UI components
- `Stepper` remindersPerDay (0–12)
- `TimeWindowPicker` start/end
- `QuietHoursPicker` start/end (optional in onboarding; in Settings always available)
- `PrimaryButton`: “Enable reminders”
- `SecondaryButton`: “Not now”

### State
- `remindersEnabledDesired: Bool`
- `notificationPermission: {unknown, granted, denied}`

### Actions
- Enable reminders:
  - request permission
  - if granted → schedule reminders
  - if denied → store desired settings but mark disabled
- Not now → proceed without scheduling

### Analytics
- `reminders_setup_completed` (props: desiredEnabled, permissionGranted, countPerDay)

### Edge cases
- User chooses 0 reminders → skip permission request.

---

## FEED-1 For You Feed

**Route:** `feed/for-you`

### Data
- `GetNextAffirmationUseCase` provides queue of cards.
- Background resolved from ThemeRepository (curated or generated).
- A “Daily affirmation” is computed once/day.

### UI components
- `AffirmationCardView`
  - `BackgroundView`
  - `AffirmationText`
  - `CategoryPill` (optional)
  - `ActionRow` (favorite, listen, share, more)
- `GentleModeChip` (optional quick toggle)
- `PaywallGateBanner` (only when premium feature tapped)

### States
- `cards: [AffirmationCardModel]` (cached)
- `currentIndex: Int`
- `isPlayingTTS: Bool`
- `isPaywallPresented: Bool`

### Actions
- Swipe next/prev:
  - prefetch next card when index approaches end
  - log `affirmation_viewed`
- Favorite:
  - toggle favorite
  - log `favorite_toggled`
- Listen:
  - start TTS
  - log `tts_played`
- Share:
  - render share image
  - open share sheet
  - log `share_started`
- More menu:
  - Not for me (P1)
  - Change categories
  - Report content
  - Theme settings

### Edge cases
- Offline: no change (local-first).
- Empty candidates (filters too strict): show “Relax filters” prompt and suggest turning off Gentle mode or adding categories.
- Large text: card reflows with max 3–5 lines and optional “tap to expand”.

---

## EXP-1 Explore

**Route:** `explore`

### UI components
- `SearchBar` (P1)
- `CategoryGrid`

### Actions
- Tap category → EXP-2 Category feed

---

## FAV-1 Favorites

**Route:** `favorites`

### UI components
- `FavoritesList`
- `SearchBar` (P1)
- Empty state view:
  - “No favorites yet”
  - CTA: “Go to For You”

---

## SET-3 Themes & Backgrounds

**Route:** `settings/themes`

### UI components
- Default theme picker (curated + My Themes)
- Curated theme pack selector
- My Themes grid
- Generate button (BG-1)

### Actions
- Tap Generate → BG-1 (if premium gated, show paywall)
- Tap Theme → set default theme
- Long press Theme → delete (for generated themes only)

---

## BG-1 Generator

**Route:** `themes/generate`

### UI components
- Style selector (segmented or cards)
- Color family selector
- Mood selector
- Detail slider
- Generate button
- Info footer: “Generated on your device.”

### States
- `canGenerate: Bool` (device gating)
- `isGenerating: Bool`
- `progress: Float`

### Actions
- Generate → BG-2 progress
- Cancel → stop task; return to BG-1

---

## SET-6 Subscription

**Route:** `settings/subscription`

### UI components
- Current plan status
- “Manage subscription” button (system)
- “Restore purchases”
- “Contact support”

---

## SET-8 Help / Crisis

**Route:** `help/crisis`

### UI components
- Headline + body
- Emergency call CTA (region picker)
- External link to local resources (configurable)
- “I’m not in crisis” dismiss

### Notes
- Must be reachable in 2 taps from app home.
