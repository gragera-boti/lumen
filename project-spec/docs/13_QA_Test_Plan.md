# 13 — QA Test Plan

## 1) Test strategy overview
- Unit tests: domain + data layer
- Integration tests: DB migrations, content pack import
- UI tests: onboarding, feed, favorites, share, reminders
- Performance tests: cold start, scrolling, share render, ML generation
- Policy/safety tests: content filters, gentle mode, sensitive topic opt-in

---

## 2) Test environments
- iOS simulators: iPhone SE (small), iPhone Pro Max (large), iPad
- Physical devices recommended:
  - Mid-tier (e.g., iPhone 14/15)
  - High-tier (iPhone 16+ if available)
  - Older supported device (if iOS version allows)

---

## 3) Critical user journeys (P0)
1. First run → onboarding → feed
2. Change categories → feed updates
3. Favorite/unfavorite → favorites screen
4. Share card → export image
5. Enable reminders → receive notification → deep link
6. Widget shows daily affirmation → tap opens app
7. Purchase premium → unlock → restore purchases

---

## 4) Test cases (sample)

### TC-OB-001: Onboarding requires at least 1 category
- Steps: open app, proceed to categories, select none, tap continue
- Expected: error state, continue disabled

### TC-FEED-010: No repeat within last N
- Steps: swipe through 60 items
- Expected: no exact duplicates within last 50

### TC-FAV-002: Favorite persists
- Steps: favorite an affirmation, force quit app, reopen
- Expected: still favorite, appears in favorites list

### TC-SHARE-001: Share image renders in correct size
- Steps: tap Share, save image
- Expected: exported image has expected resolution and readable text

### TC-NOTIF-005: Quiet hours respected
- Configure quiet hours 22:00–07:00, reminders 3/day
- Expected: none scheduled within quiet hours

### TC-ML-003: Cancel generation
- Start generation, cancel midway
- Expected: no theme saved; UI returns to generator screen

### TC-ML-004: Fallback on unsupported device
- On unsupported device tier, open generator
- Expected: shows “not supported”, offers curated themes

---

## 5) Performance budgets
- Cold start to first card: < 1.0s (excluding model download)
- Feed swipe: 60 fps feel on modern devices; no jank
- Share render: < 400ms
- Background generation: <= 12s on supported tier

---

## 6) Security/privacy tests
- Verify no custom affirmation text sent to analytics
- Verify “Delete all data” removes DB and images
- Verify network calls are TLS

---

## 7) Regression suite
Run for every release:
- Onboarding path
- Notifications schedule & deep link
- Widget refresh
- Purchases and restore
- Content pack import
