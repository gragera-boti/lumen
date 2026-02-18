# 11 — Subscriptions & Paywall

## 1) Product strategy
Free tier should deliver real value (trust), while premium offers meaningful upgrades:
- More categories + curated packs
- Unlimited background generation
- Watermark removal on shares
- Extra widget styles (optional)
- Advanced personalization (P1)

---

## 2) Entitlement model

### 2.1 Entitlements
- `premium_active` (boolean)

### 2.2 Mapping to Store products
- `lumen.premium.monthly`
- `lumen.premium.yearly`
- `lumen.premium.lifetime`

(Exact IDs must match App Store Connect.)

### 2.3 Grace periods and offline
- Cache entitlement for 7 days.
- If receipt check fails temporarily, keep premium for 24h (grace) to avoid user disruption.

---

## 3) Paywall placement

### 3.1 MVP paywall triggers
- After onboarding (optional), but only after showing at least 3 free affirmations (value demo).
- When user taps a premium category.
- When user tries to generate > N backgrounds (free cap).
- When toggling watermark off.

### 3.2 Frequency caps
- Do not show paywall more than once per 24h unless user explicitly taps premium feature.

---

## 4) Paywall content requirements
- Clear pricing and renewal language
- Restore purchases button
- Link to Terms and Privacy
- Trial terms: duration, auto-renewal, cancel instructions

---

## 5) Implementation notes (iOS)
- StoreKit 2 product fetch
- Transaction listener on app start
- Receipt validation:
  - On-device validation acceptable for MVP
  - Server-side validation recommended for fraud reduction (P1)

---

## 6) Implementation notes (Android) — if built
- Google Play Billing library
- Acknowledge purchases properly
- Use Play Console subscription base plans/offers

---

## 7) Feature gating matrix (example)

| Feature | Free | Premium |
|---|---:|---:|
| Daily feed | ✅ | ✅ |
| Favorites | ✅ | ✅ |
| Widgets | ✅ | ✅ |
| Category count | Limited | All |
| Background generation | 3/week | Unlimited |
| Watermark removal | ❌ | ✅ |
| Advanced themes | Limited | All |
| Smart reminders | ❌ | ✅ (P1) |

---

## 8) Restore & manage subscription
- iOS: “Manage Subscription” deep-link to system subscription page.
- Android: open Play subscription management.

---

## 9) Subscription settings screen
- Current plan
- Renewal date (if applicable)
- Cancel instructions
- Restore purchases
- Contact support
