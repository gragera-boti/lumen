# 15 — Roadmap & Sprints (Sequence, not dates)

This is a recommended **build sequence** for an engineering agent.

---

## Phase 0 — Foundations
- Repo + CI skeleton
- App Group setup (for widgets)
- Local DB schema + migrations
- Content pack loader + validation

Deliverable: app can display a static “Affirmation of the Day” from bundled pack.

---

## Phase 1 — MVP core
- Onboarding (categories, tone, reminders)
- Feed (swipe, caching, selection algorithm)
- Favorites + history
- Share image rendering
- TTS playback
- Settings basics (filters, voice, data reset)
- iOS Widgets
- Basic analytics layer (optional)
- Paywall + StoreKit 2

Deliverable: app is shippable without ML generation.

---

## Phase 2 — On-device ML backgrounds
- Model download + checksum verification
- Restricted background generator UI
- Generation pipeline + cancel
- Save to My Themes
- Storage caps and eviction
- Safety scaffolding + reporting UI

Deliverable: safe on-device generation shipped.

---

## Phase 3 — Post-MVP improvements
- Apple Watch app + complications (optional)
- “Not for me” dislike + suppression
- Search in favorites/history
- Content pack remote updates (optional backend)

---

## Phase 4 — v2 expansions
- Journeys (7/14/21-day)
- On-device smart reminder timing
- Cloud sync (if desired)
- Android version
