# 10 — Notifications, Widgets, and Watch (iOS)

## 1) Reminders: product behavior

### 1.1 Reminder types
- **Daily schedule:** N reminders/day within a time window
- **Fixed times:** user selects exact times (P1)
- **Smart schedule:** on-device model suggests best times (P1)

### 1.2 Notification content rules
- Keep text short enough for lock screen.
- No sensitive-topic content unless user opted in.
- No medical claims.

### 1.3 Quiet hours
- App-level quiet hours prevent scheduling notifications in that range.
- If OS Focus blocks delivery, app should inform user in Reminders screen (hint only).

---

## 2) Implementation: scheduling local notifications

### 2.1 Algorithm (MVP)
Inputs:
- remindersPerDay (0–12)
- windowStart, windowEnd
- quietStart, quietEnd
- timezone (device)

Process:
1. Generate candidate times uniformly spaced in window (or random within sub-windows).
2. Remove times that fall in quiet hours.
3. If too few times remain, reduce count and show hint.
4. Schedule notifications for next 7 days (rolling), each with a deep link.

### 2.2 Rolling reschedule
- On app open (once/day), reschedule next 7 days to:
  - incorporate new preferences
  - incorporate new content pack
  - avoid repeating same affirmation too often

### 2.3 Notification payload
- `title`: “Lumen”
- `body`: short affirmation text
- `userInfo`: { `affirmationId`, `deeplink` }

---

## 3) Widgets (WidgetKit)

### 3.1 Widget types
- Small: 1–2 lines of affirmation + background
- Medium: affirmation + category label
- Large: affirmation + “Next” hint + subtle gradient

### 3.2 Data source
Widgets read from a lightweight snapshot JSON stored in App Group:
- `widget_snapshot.json`
  - `affirmationOfDay`
  - `themeId`
  - `lastUpdatedAt`

App updates snapshot:
- After onboarding complete
- Daily at midnight local time
- When user changes categories/theme

### 3.3 Timeline policy
- Update at least daily.
- Optional: update 3×/day if user prefers (respect OS limits).

---

## 4) Deep links

### 4.1 Notification open
If user taps notification:
- App opens `affirmationId` and renders that card.
- If missing, fallback to daily affirmation.

### 4.2 Widget tap
- Widget tap opens `lumen://affirmation/{id}` or `lumen://feed`.

---

## 5) Apple Watch (P1)

### 5.1 Watch app screens
- Current affirmation
- Favorite button
- Next button
- Settings shortcut (reminders)

### 5.2 Data sync
- Use shared storage or WatchConnectivity for sync.
- Keep only small data set on watch to save space.

### 5.3 Complications
- Short text snippet (truncated)
- Refresh daily

---

## 6) Testing checklist
- Notifications scheduled correctly across DST changes.
- Quiet hours respected.
- Widget snapshot updated after changes.
- Deep links open correct screen even cold start.
