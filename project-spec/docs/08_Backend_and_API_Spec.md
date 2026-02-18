# 08 — Backend & API Spec (Optional)

## 1) When you need a backend
MVP can ship without any backend. Add backend if you want:
- Remote content pack updates
- Cross-device sync across Apple + Android
- Remote config / experiments
- Web-based admin tooling

If you only target Apple platforms, consider **iCloud / CloudKit** instead of a custom backend.

---

## 2) Core backend responsibilities
1. Content distribution:
   - Serve versioned content packs per locale.
   - Provide signed URLs and checksums.
2. User sync (optional):
   - Store user settings/favorites securely.
3. Remote config:
   - Feature flags, paywall variants.
4. Abuse prevention:
   - Rate limit any report endpoints.

---

## 3) Data model (server-side)
- Users
  - `user_id` (UUID)
  - `provider` (apple/google/email)
  - `created_at`
- UserData
  - `favorites[]`
  - `preferences` (filtered)
  - `custom_affirmations[]` (encrypted if possible)
- ContentPacks
  - `pack_id`
  - `locale`
  - `version`
  - `checksum_sha256`
  - `url`
- Reports (for AI-generated images)
  - `report_id`, `user_id?`, `theme_id`, `reason`, `created_at`

---

## 4) Authentication options
- iOS: Sign in with Apple (recommended)
- Android: Google Sign-In
- Anonymous device ID for content updates only (no personal data)

---

## 5) API summary
Full OpenAPI: `assets/openapi/openapi.yaml`

### 5.1 Content
- `GET /v1/content/manifest?locale=en-GB`
- `GET /v1/content/packs/{packId}` (or signed URL)

### 5.2 Remote config
- `GET /v1/config?platform=ios&appVersion=1.0.0`

### 5.3 Sync (opt-in)
- `POST /v1/auth/apple` (exchange identity token)
- `GET /v1/user/data`
- `PUT /v1/user/data`

### 5.4 Reporting (for generative images)
- `POST /v1/reports/image`
  - Minimal payload: generated theme metadata (no image upload by default)
  - If user opts in, allow attaching image thumbnail.

---

## 6) Security requirements
- TLS everywhere
- JWT access tokens (short-lived) + refresh tokens (rotating)
- Store minimal personal data
- Encrypt at rest (DB)
- Consider end-to-end encryption for custom affirmations (P2)

---

## 7) Rate limits
- Content manifest: 60/min per IP
- Reports: 10/day per device (tunable)

---

## 8) Admin tooling (optional)
- Upload new content pack
- Validate content schemas
- Roll out by percentage (remote config)
- View aggregated report counts
