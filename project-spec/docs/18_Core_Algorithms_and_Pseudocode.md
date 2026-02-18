# 18 — Core Algorithms & Pseudocode

This document gives implementation-grade pseudocode for key behaviors.

---

## 1) Feed selection: `GetNextAffirmationUseCase`

### 1.1 Inputs
- `prefs`: UserPreferences
- `now`: Date
- repositories: affirmations, favorites, dislikes, history

### 1.2 Candidate query (SQL-ish)
```sql
SELECT a.*
FROM affirmations a
JOIN affirmation_categories ac ON ac.affirmation_id = a.id
WHERE a.locale = :locale
  AND ac.category_id IN (:selectedCategoryIds)
  AND (a.sensitive_topic = 0 OR :includeSensitiveTopics = 1)
  AND a.id NOT IN (SELECT affirmation_id FROM dislikes)
  AND a.id NOT IN (
      SELECT affirmation_id FROM seen_events
      ORDER BY seen_at DESC
      LIMIT :recentLimit
  )
  AND (:gentleMode = 0 OR (a.intensity != 'HIGH' AND a.absolute = 0))
  AND (:spiritualFilter = 1 OR a.tone != 'SPIRITUAL')
  AND (:tonePreset = 'ANY' OR a.tone = :tonePreset)
;
```

### 1.3 Weighted pick (pseudocode)
```pseudo
function nextAffirmation(prefs):
  candidates = queryCandidates(prefs)

  if candidates empty:
    candidates = relaxConstraintsInOrder(prefs)

  scored = []
  for a in candidates:
    score = 1.0

    // Category match
    score *= 1.2

    // Tone boost if matches preference
    if a.tone == prefs.tonePreset: score *= 1.15

    // Favorites similarity boost (simple tag overlap with last 20 favorites)
    overlap = countOverlap(a.tags, recentFavoriteTags(20))
    score *= (1.0 + min(overlap, 3) * 0.08)

    // Novelty boost
    lastSeenDays = daysSinceLastSeen(a.id)
    score *= (1.0 + clamp(lastSeenDays/14, 0, 1) * 0.15)

    // Premium gating: if not premium user, downweight premium items (or exclude)
    if a.isPremium and not entitlement.premiumActive:
       score *= 0.05  // effectively exclude but keep fallback

    scored.append((a, score))

  return weightedRandom(scored)
```

### 1.4 Relaxation order
1. allow older seen events (increase recentLimit from 50 → 20)
2. allow other tones (except spiritual filter)
3. allow “generic” categories (a curated fallback bucket)
4. show “No more items” only if DB is truly empty

---

## 2) Dislike suppression

```pseudo
function dislike(affirmationId, reason):
  dislikes.upsert({affirmationId, now, reason})
  // Also remove from current card cache to avoid re-showing
```

Suppression window:
- Default: 90 days
- Implementation: keep indefinitely; query only excludes items in dislikes table.
- Optionally allow “Reset dislikes” in Settings.

---

## 3) Reminder scheduling

### 3.1 Generate times in a window
```pseudo
function scheduleReminders(prefs):
  if prefs.reminders.countPerDay == 0: cancelAll(); return

  windowStart = todayAt(prefs.reminders.windowStart)
  windowEnd   = todayAt(prefs.reminders.windowEnd)
  if windowEnd <= windowStart: windowEnd += 1 day  // support windows crossing midnight (optional)

  times = []
  interval = (windowEnd - windowStart) / prefs.reminders.countPerDay
  for i in 0..countPerDay-1:
    t = windowStart + i*interval + random(-interval*0.2, interval*0.2)
    if isInQuietHours(t, prefs): continue
    times.append(t)

  // Ensure enough times; if too few, backfill by expanding random jitter or lowering count.
  times = ensureCount(times, prefs.reminders.countPerDay)

  // Schedule next 7 days rolling
  for day in 0..6:
     for t in times:
        scheduleLocalNotification(at: t + day days, payload: pickNotificationAffirmation())
```

### 3.2 Picking affirmation for notifications
- Prefer “short” variants.
- Exclude sensitive topics unless opted in.
- Prefer gentle mode if enabled.

---

## 4) Share image rendering

### 4.1 Requirements
- Must render consistent output sizes for social sharing.
- Must preserve text legibility.

### 4.2 Suggested output sizes (iOS)
- Instagram Story: 1080×1920
- Square: 1080×1080
- Universal: 1200×1600

### 4.3 Pseudocode
```pseudo
function renderShareImage(card, size):
  bg = loadBackground(card.theme)
  canvas = newCanvas(size)
  canvas.drawImage(bg, fill)
  overlay = computeReadabilityOverlay(bg)
  canvas.drawOverlay(overlay)
  canvas.drawText(card.text, style=dynamicTypeAware)
  if watermarkEnabled: canvas.drawWatermark("Lumen")
  return canvas.exportPNG()
```

---

## 5) Text readability overlay

### 5.1 Heuristic approach (MVP)
- Compute average luminance behind text area.
- If luminance too high or too low (low contrast), apply:
  - semi-transparent dark/light gradient
  - or blur behind text (rounded rect “glass”)

### 5.2 Pseudocode
```pseudo
function computeReadabilityOverlay(bgImage):
  region = centerTextRegion(bgImage)
  lum = averageLuminance(region)
  if lum > 0.7:
     return darkGradient(opacity=0.35)
  if lum < 0.3:
     return lightGradient(opacity=0.25)
  return subtleGradient(opacity=0.18)
```

---

## 6) Background generation prompt composition

```pseudo
function buildPrompt(styleId, colorFamilyId, moodId, detailLevel):
  style = styles[styleId]
  colors = colorFamilies[colorFamilyId].adjectives
  mood = moods[moodId].adjectives

  detailAdj = if detailLevel < 0.33 then "minimal"
              else if detailLevel < 0.66 then "medium detail"
              else "high detail"

  prompt = style.basePrompt + ", " + join(colors) + ", " + join(mood) + ", " + detailAdj
  negative = style.negativePrompt
  return (prompt, negative)
```

---

## 7) Widget snapshot update

```pseudo
function updateWidgetSnapshot():
  daily = computeDailyAffirmation()
  theme = prefs.themeId
  snapshot = { dailyAffirmationId: daily.id, text: daily.text, themeId: theme, updatedAt: now }
  writeJSON(appGroupPath("widget_snapshot.json"), snapshot)
  WidgetCenter.shared.reloadAllTimelines()
```
