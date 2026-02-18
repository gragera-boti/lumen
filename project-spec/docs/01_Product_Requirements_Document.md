# 01 — Product Requirements Document (PRD)

## 1. Product summary

**Lumen** is a daily affirmations app (similar to “I am – Daily Affirmations”) that delivers short, positive, psychologically safe statements as:
- A swipeable in-app feed
- Scheduled push notifications
- Home screen widgets and watch complications
- Shareable images

Lumen differs by:
1) **Evidence-aligned messaging rules**: avoids unrealistic “forced positivity” and supports more self-compassionate framing.
2) **On-device ML background generation**: generate custom calming/beautiful backgrounds with privacy-preserving image generation.
3) **Optional on-device personalization**: chooses content and reminder timing without uploading private data.

---

## 2. Problem statement

Users want short, uplifting reminders throughout the day. Many existing apps succeed at delivering positive content, but can fail in 3 ways:

1) **Content mismatch**: “Be grateful for your health” can feel invalidating for people with chronic illness; “I am amazing” can backfire for users with low self-esteem.
2) **Generic experience**: same content/time schedule for everyone; poor retention.
3) **Privacy concerns**: personalization often relies on cloud profiling.

---

## 3. Goals & success metrics

### 3.1 Primary goals
- Deliver a fast, joyful “micro-moment” experience (affirmation in < 1 second from app open).
- Keep the product safe and honest: no disease claims, no guaranteed outcomes, no shaming language.
- Make personalization useful while remaining privacy-first.

### 3.2 MVP success metrics (first 60 days post-launch)
- D1 retention ≥ 35%
- D7 retention ≥ 12%
- 30-day retained users who enable notifications ≥ 45%
- Average daily sessions among retained users ≥ 2.0
- Share action rate among retained users ≥ 10%/week
- Crash-free sessions ≥ 99.7%
- App Store rating ≥ 4.6 after 1,000 ratings

### 3.3 Monetization metrics
- Trial start rate (from paywall impressions) ≥ 3%
- Trial conversion ≥ 35%
- Monthly churn ≤ 8% after month 2

---

## 4. Target users & personas

### Persona A — “Busy Optimizer”
- Wants quick boosts, no journaling.
- Values widgets + reminders.
- Likes aesthetic visuals.

### Persona B — “Anxious/Overwhelmed”
- Wants calming, non-judgmental content.
- Sensitive to overly intense or unrealistic affirmations.
- Prefers gentle reminders, quiet hours, and softer tone.

### Persona C — “Health Challenge / Caregiver”
- Experiences chronic stress; needs validation.
- Wants categories that avoid “health gratitude” clichés.
- Benefits from self-compassion and resilience framing.

### Persona D — “Spiritual Seeker”
- Wants optional spiritual language, but not forced on everyone.
- Wants to toggle spiritual content on/off.

---

## 5. Competitive landscape (quick notes)

The reference app (“I am – Daily Affirmations”) emphasizes:
- Category selection, reminders, widgets, watch support, and themes/backgrounds
- Subscription (monthly/yearly/lifetime) for premium content and customization

Observations from public reviews:
- Users love quick watch/widget access and customizable reminders.
- Some complain about cross-device sync reliability.
- Some users feel certain affirmations don’t fit serious contexts (e.g., illness).

Lumen’s spec addresses these by:
- Stronger content filters and “sensitivity” tagging.
- Optional account-based sync designed for correctness (or iCloud-only for Apple ecosystem).

---

## 6. Scope

### 6.1 MVP scope (must ship)
- Swipe feed with affirmation cards and backgrounds
- Category selection and “For You” feed
- Favorites and history
- Share as image (with watermark toggle for premium)
- Text-to-speech playback
- Reminders: schedule, frequency, quiet hours
- iOS home screen widget (small/medium/large)
- Paywall, subscriptions, restore purchases
- On-device ML background generation (limited styles, curated prompts)
- Safety & compliance: disclaimers, crisis/help, content guardrails
- Analytics with privacy-respecting defaults

### 6.2 v1+ scope (post-MVP)
- Apple Watch app + complications
- Android version (parity features)
- Cloud sync (favorites, themes, custom affirmations)
- “Journeys” (7/14/21-day packs)
- On-device “smart reminder timing” model
- In-app “values reflection” mini-exercise

### 6.3 Out of scope (explicit)
- Therapy chatbots or diagnosis tools
- Mood disorder screening or medical recommendations
- Social feed, communities, or messaging
- User-to-user content sharing inside the app
- Free-form image generation prompts without guardrails

---

## 7. Assumptions & constraints
- iOS baseline: iOS 18+ (or iOS 17+ if needed), because ML features and widgets are first-class.
- Background generation is optional and must degrade gracefully on unsupported devices.
- MVP content library: 2,000–5,000 curated affirmations in English; additional locales later.

---

## 8. Risks (high level)
- “Affirmations don’t work for me” → mitigate via tone personalization + self-compassion alternatives.
- Generative images policy compliance → mitigate via restricted prompt UI + safety checks + user reporting.
- Subscription churn → mitigate via “value” (widgets, themes, unlimited generation) and flexible reminders.

---

## 9. Stakeholders
- Product owner / founder
- iOS engineer(s)
- ML engineer (part-time)
- Content editor (psychology-informed)
- Designer
- Legal/privacy reviewer (for policies)

---

## 10. Glossary
- **Affirmation**: a short statement meant to encourage helpful self-talk.
- **Self-affirmation (theory)**: a research area often involving values reflection, distinct from repeating positive self-statements.
- **On-device ML**: inference performed locally on the user device (no server).
