# 07 — Data Model & Storage (Local-first)

## 1) Storage approach

### 1.1 Requirements
- Fast random access for feed
- Efficient “avoid repeats” queries
- Widget-safe shared storage
- Migrations as content packs evolve

### 1.2 Recommendation
Use SQLite with either:
- GRDB (Swift)
- SQLDelight (if using KMP later)

---

## 2) Entity overview

### 2.1 Core entities
- `Affirmation`
- `Category`
- `Theme` (curated or generated)
- `UserPreferences`
- `Favorite`
- `SeenEvent` (history)
- `Dislike`
- `EntitlementState` (cached)

---

## 3) SQLite schema (suggested)

### 3.1 Table: categories
```sql
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  locale TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  is_premium INTEGER NOT NULL DEFAULT 0,
  is_sensitive INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_categories_locale ON categories(locale);
```

### 3.2 Table: affirmations
```sql
CREATE TABLE affirmations (
  id TEXT PRIMARY KEY,
  locale TEXT NOT NULL,
  text TEXT NOT NULL,
  tone TEXT NOT NULL,                -- GENTLE|NEUTRAL|ENERGETIC|SPIRITUAL
  intensity TEXT NOT NULL,           -- LOW|MEDIUM|HIGH
  absolute INTEGER NOT NULL DEFAULT 0,
  sensitive_topic INTEGER NOT NULL DEFAULT 0,
  is_premium INTEGER NOT NULL DEFAULT 0,
  source TEXT NOT NULL,              -- CURATED|USER
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_affirmations_locale ON affirmations(locale);
CREATE INDEX idx_affirmations_tone ON affirmations(tone);
```

### 3.3 Join: affirmation_categories
```sql
CREATE TABLE affirmation_categories (
  affirmation_id TEXT NOT NULL REFERENCES affirmations(id) ON DELETE CASCADE,
  category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  PRIMARY KEY (affirmation_id, category_id)
);
CREATE INDEX idx_aff_cat_cat ON affirmation_categories(category_id);
```

### 3.4 Table: tags + join
```sql
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE affirmation_tags (
  affirmation_id TEXT NOT NULL REFERENCES affirmations(id) ON DELETE CASCADE,
  tag_id TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (affirmation_id, tag_id)
);
```

### 3.5 Table: favorites
```sql
CREATE TABLE favorites (
  affirmation_id TEXT PRIMARY KEY REFERENCES affirmations(id) ON DELETE CASCADE,
  favorited_at INTEGER NOT NULL
);
```

### 3.6 Table: seen_events (history)
```sql
CREATE TABLE seen_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  affirmation_id TEXT NOT NULL REFERENCES affirmations(id) ON DELETE CASCADE,
  seen_at INTEGER NOT NULL,
  source TEXT NOT NULL,              -- FEED|WIDGET|NOTIFICATION
  session_id TEXT
);
CREATE INDEX idx_seen_recent ON seen_events(seen_at DESC);
CREATE INDEX idx_seen_affirmation ON seen_events(affirmation_id);
```

### 3.7 Table: dislikes
```sql
CREATE TABLE dislikes (
  affirmation_id TEXT PRIMARY KEY REFERENCES affirmations(id) ON DELETE CASCADE,
  disliked_at INTEGER NOT NULL,
  reason TEXT
);
```

### 3.8 Table: themes
```sql
CREATE TABLE themes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,                -- CURATED_IMAGE|GRADIENT|GENERATED_IMAGE
  is_premium INTEGER NOT NULL DEFAULT 0,
  data_json TEXT NOT NULL,           -- see ThemeData structure
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### 3.9 Table: user_preferences (singleton)
```sql
CREATE TABLE user_preferences (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  locale TEXT NOT NULL,
  tone_preset TEXT NOT NULL,
  gentle_mode INTEGER NOT NULL DEFAULT 1,
  selected_category_ids_json TEXT NOT NULL,
  include_sensitive_topics INTEGER NOT NULL DEFAULT 0,
  content_filters_json TEXT NOT NULL,
  reminders_json TEXT NOT NULL,
  voice_json TEXT NOT NULL,
  theme_id TEXT,
  analytics_opt_out INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
);
INSERT INTO user_preferences (id, locale, tone_preset, selected_category_ids_json, content_filters_json, reminders_json, voice_json, updated_at)
VALUES (1, 'en-GB', 'GENTLE', '[]', '{}', '{}', '{}', strftime('%s','now'));
```

### 3.10 Table: entitlement_state (cached)
```sql
CREATE TABLE entitlement_state (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  is_premium INTEGER NOT NULL DEFAULT 0,
  product_id TEXT,
  expires_at INTEGER,
  updated_at INTEGER NOT NULL
);
```

---

## 4) ThemeData JSON structure

### 4.1 Curated image
```json
{
  "assetName": "bg_sunset_01",
  "blur": 0,
  "overlay": { "type": "gradient", "opacity": 0.25 }
}
```

### 4.2 Gradient
```json
{
  "colors": ["#1B998B", "#ED217C"],
  "angleDeg": 45,
  "noise": 0.06
}
```

### 4.3 Generated image (on-device ML)
```json
{
  "filePath": "appgroup://themes/generated/abc123.png",
  "generator": {
    "model": "coreml-stable-diffusion-v1-5-palettized",
    "styleId": "MIST",
    "seed": 12345678,
    "steps": 20,
    "guidanceScale": 7.0,
    "size": 512
  },
  "safety": {
    "classifierVersion": "v1",
    "score": 0.02,
    "blocked": false
  }
}
```

---

## 5) Content pack ingestion

### 5.1 Content pack file layout
- `categories.json`
- `affirmations.json`
- `meta.json` (version, locale, checksum)

### 5.2 Ingestion strategy
- Validate JSON schemas.
- Insert/update by `id`.
- Keep `deleted` list for removals (soft delete recommended to preserve history).
- Migrate schema if needed.

---

## 6) Feed selection algorithm (storage-dependent rules)

### 6.1 Inputs
- `selectedCategoryIds`
- `tonePreset`
- `gentleMode`
- `favorites` (boost)
- `dislikes` (suppress)
- `seen_events` recency (avoid repeats)

### 6.2 Query strategy
1. Build candidate set by category + locale + tone filtering.
2. Exclude disliked and recently seen.
3. Weighted random pick by:
   - category match weight
   - tag similarity to recent favorites
   - novelty boost
4. If no candidates, relax constraints in order:
   - allow older seen items
   - allow other tones (except if gentle mode ON)
   - allow generic categories (fallback bucket)

---

## 7) Optional cloud sync (P1)
If enabled, sync only:
- favorites
- custom affirmations
- selected categories & settings
- themes list (metadata) + generated image files (optional; could be too big)

Conflict resolution:
- Preferences: last-write-wins by updated_at per field group.
- Favorites: union of sets; on conflict, keep most recent timestamp.
