# 14 — Analytics & Experiments (Privacy-first)

## 1) Principles
- Collect the minimum needed to improve the product.
- Do not log user-generated text.
- Avoid collecting health signals (mood, diagnoses).
- Provide opt-out if required.

---

## 2) Core events (MVP)

### 2.1 Onboarding
- `onboarding_started`
- `onboarding_completed`
  - props: selected_category_count, tone, reminders_per_day, notif_permission (granted/denied)

### 2.2 Engagement
- `affirmation_viewed`
  - props: source (feed/widget/notif), category_ids (hashed or count only), tone, gentle_mode
- `favorite_toggled`
  - props: is_favorite, source
- `share_started`
  - props: destination (unknown/other), watermark_enabled
- `tts_played`
  - props: rate

### 2.3 Reminders
- `reminders_enabled`
- `reminder_scheduled`
  - props: count_next_7_days
- `reminder_opened`
  - props: deep_link_success

### 2.4 ML generation
- `bg_generation_started`
  - props: styleId, tier, steps
- `bg_generation_completed`
  - props: duration_ms, success
- `bg_generation_cancelled`
- `bg_generation_failed`
  - props: error_code

### 2.5 Monetization
- `paywall_viewed`
  - props: trigger
- `purchase_started`
  - props: product_id
- `purchase_completed`
  - props: product_id
- `purchase_failed`
  - props: product_id, reason
- `restore_completed`

---

## 3) Privacy constraints
- Do not include `affirmationId` in analytics (could be used to infer sensitive categories).
- If needed, send only coarse category buckets or counts.
- Do not log exact reminder times; log counts and window sizes.

---

## 4) Experiment framework (P1)
- Remote config returns:
  - `paywall_variant`: A/B/C
  - `free_generation_cap`: e.g., 3/week vs 1/day
- Assignment:
  - deterministic hash(device_id + experiment_id) % 100
- Store assignment locally.

---

## 5) Guardrails
- Never experiment with:
  - removing crisis/help access
  - pushing sensitive topics without opt-in
  - aggressive notification frequency above user selection
