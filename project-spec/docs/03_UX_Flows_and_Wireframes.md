# 03 — UX Flows and Wireframes (Implementation-Ready)

## 1) Navigation model

### 1.1 iOS tab bar (MVP)
Tabs:
1. **For You** (Feed)
2. **Explore** (Categories)
3. **Favorites**
4. **Settings**

Optional center action button (P1): “Create” (custom affirmation).

### 1.2 Deep link routes
- `lumen://affirmation/{affirmationId}`
- `lumen://category/{categoryId}`
- `lumen://favorites`
- `lumen://settings/reminders`
- `lumen://paywall`
- `lumen://help/crisis`

---

## 2) Screen inventory (MVP)

### Onboarding
- OB-1 Welcome + disclaimer
- OB-2 Choose categories
- OB-3 Choose tone
- OB-4 Reminders setup + permission prompt
- OB-5 Paywall (optional; recommended after value demo)
- OB-6 Done → Feed

### Main experience
- FEED-1 For You feed
- FEED-2 Card share sheet
- FEED-3 Card details (optional)
- EXP-1 Explore category grid
- EXP-2 Category feed
- FAV-1 Favorites list
- FAV-2 Favorite detail
- SET-1 Settings home
- SET-2 Reminders
- SET-3 Themes & Backgrounds
- SET-4 Voice
- SET-5 Filters
- SET-6 Subscription
- SET-7 Privacy & Data
- SET-8 Help / Crisis resources

### ML background generation
- BG-1 Background generator setup
- BG-2 Generation progress
- BG-3 Save to My Themes

---

## 3) Wireframes (ASCII)

### OB-1 Welcome

┌─────────────────────────────────────────────┐
│  Lumen                                       │
│  Daily affirmations that feel kind — not     │
│  forced.                                     │
│                                             │
│  • Quick inspiration in widgets & reminders  │
│  • Gentle mode for tough days                │
│  • Optional on-device background generation  │
│                                             │
│  Wellness notice: This app is not medical    │
│  care. If you feel unsafe or in crisis,      │
│  tap “Get help now”.                         │
│                                             │
│  [Get help now]          [Continue]          │
└─────────────────────────────────────────────┘

**Key decisions**
- Keep copy short; user can tap “Learn more” if desired.
- “Continue” must not request permissions yet.

---

### OB-2 Choose categories

┌─────────────────────────────────────────────┐
│ Choose what you want more of                 │
│ (Pick at least one)                          │
│                                             │
│ [ ] Self-love     [ ] Confidence             │
│ [ ] Calm          [ ] Motivation             │
│ [ ] Relationships [ ] Work & Focus           │
│ [ ] Gratitude     [ ] Sleep wind-down        │
│ [ ] Resilience    [ ] Boundaries             │
│                                             │
│  (Optional) Include sensitive topics         │
│  [ ] Grief  [ ] Chronic illness              │
│                                             │
│                         [Continue]           │
└─────────────────────────────────────────────┘

Notes:
- “Sensitive topics” are off by default to avoid surprise content.
- Category list is localized and remotely configurable.

---

### FEED-1 For You Feed (card)

┌─────────────────────────────────────────────┐
│  (Background image)                          │
│                                             │
│   “I can take one small step today.”         │
│                                             │
│    [♡] Favorite   [▶︎] Listen   [↗] Share     │
│                                             │
│    ⋯ More                                  │
└─────────────────────────────────────────────┘

Gesture:
- Swipe up: next card
- Swipe down: previous card (within cache)

Overflow menu (⋯):
- Not for me (dislike)
- Change categories
- Report content
- Open theme settings

---

### EXP-1 Explore (category grid)

┌─────────────────────────────────────────────┐
│ Explore                                     │
│  Search …                                   │
│                                             │
│ [Self-love]  [Confidence]  [Calm]            │
│ [Motivation] [Sleep]       [Gratitude]       │
│ ...                                         │
└─────────────────────────────────────────────┘

---

### SET-2 Reminders

┌─────────────────────────────────────────────┐
│ Reminders                                   │
│                                             │
│ Reminders per day:   [ 3 ]  (0–12)           │
│ Time window:         09:00 — 21:00           │
│ Quiet hours:         22:00 — 07:00           │
│                                             │
│ Message length: [Short|Medium]               │
│ Include emoji:  [On/Off]                     │
│                                             │
│ [Send test notification]                     │
│                                             │
│ Notification permission: Enabled/Disabled    │
└─────────────────────────────────────────────┘

Edge cases:
- If permission is off, show call-to-action and steps.
- If OS Focus mode blocks notifications, show hint.

---

### SET-3 Themes & Backgrounds

┌─────────────────────────────────────────────┐
│ Themes & Backgrounds                         │
│                                             │
│ Default theme:  [Sunset Gradient ▾]          │
│                                             │
│ Curated themes:                              │
│  [ ] Minimal   [ ] Nature   [ ] Abstract     │
│                                             │
│ My themes:                                   │
│  (grid of thumbnails)                        │
│                                             │
│ [Generate new background]                    │
└─────────────────────────────────────────────┘

---

### BG-1 Generate background (restricted prompt UI)

┌─────────────────────────────────────────────┐
│ Generate background                           │
│                                             │
│ Style:  ( ) Abstract  ( ) Nature  ( ) Mist   │
│ Color:  ( ) Warm      ( ) Cool    ( ) Mono   │
│ Mood:   ( ) Calm      ( ) Hopeful ( ) Focus  │
│                                             │
│ Detail level:  Low ————●——— High             │
│                                             │
│ [Generate]                                   │
│                                             │
│ Note: Images are generated on your device.   │
└─────────────────────────────────────────────┘

---

## 4) Copy / messaging rules embedded in UX

- Avoid absolute promises (“This will change your life.”)
- Offer “Try a gentler version” when user dislikes content repeatedly.
- Never shame: replace “You should…” with “You might try…”

---

## 5) Accessibility UX checklist
- Minimum tap target 44×44pt.
- Text must remain readable on high-contrast and large text.
- VoiceOver order: background (ignored), affirmation text (read), actions.

---

## 6) User flow diagrams (Mermaid pointers)
See `assets/diagrams/architecture.mermaid` and `assets/diagrams/dataflow.mermaid`.
