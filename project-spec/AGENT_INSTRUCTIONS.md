# Coding Agent Kickoff Instructions

Use this file as the “entrypoint” for implementation.

## 1) Decide build target(s)
MVP is **iOS (SwiftUI)**. Android parity is optional and specified as “v1+”.

## 2) Build order (recommended)
1. Local-first content & feed: Affirmation cards, categories, favorites, share, TTS.
2. Reminders/notifications + widget.
3. Settings + content filters + accessibility.
4. Monetization (StoreKit 2).
5. On-device ML background generation (guardrails + caching).
6. Optional cloud sync + content delivery backend.

## 3) Definition of Done (DoD)
A feature is “done” when:
- Acceptance criteria in `docs/02_Functional_Requirements.md` are met.
- Unit tests exist for core logic and data layer.
- UI tests cover core flows: onboarding, view affirmation, favorite, share, reminders.
- Crash-free; performance budgets met (see QA doc).

## 4) Non-negotiables
- Do not ship unsafe mental-health claims.
- Do not allow unmoderated free-form image prompts (see ML doc).
- Privacy-first defaults; no account required for MVP.
- Provide a clear “Get help now” path in Settings and at first-run.

## 5) File-level map
- Product: `docs/01_*`
- Requirements: `docs/02_*`
- UX: `docs/03_*`
- ML: `docs/09_*`
- API: `docs/08_*`
- Schemas: `assets/schemas/*`
- Sample content: `assets/sample_content/*`
