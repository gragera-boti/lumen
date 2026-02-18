# 09 — On-Device ML: Background Generation & Optional Personalization

## 1) Goals
- Generate beautiful, calming backgrounds **on-device** (privacy + latency).
- Make generation safe and policy-compliant.
- Provide predictable performance and graceful fallback.

Non-goals:
- Free-form text-to-image prompt chat
- Photorealistic people or celebrities
- Style transfer from user photos (not in MVP)

---

## 2) Model choice (iOS)

### 2.1 Recommended approach
Use Apple’s Core ML Stable Diffusion tooling:
- `apple/ml-stable-diffusion` Swift package for inference
- A Core ML Stable Diffusion model variant suitable for iOS (quantized/palettized)

### 2.2 Model packaging
**Problem:** Including model weights in app bundle can bloat app size.

**Recommendation (MVP):**
- Ship with curated themes only.
- Offer optional in-app download of model on first use of generator:
  - Download to Application Support / App Group container
  - Verify SHA-256 checksum before use
  - Allow user to delete downloaded model in Settings (“Storage”)

### 2.3 Device gating
Background generation is enabled only if:
- iOS version supports required ops
- Device meets minimum memory/Neural Engine capability
- Battery not critically low (optional)
- Thermal state not “serious/critical” (optional)

If unsupported, show:
- “Your device can’t generate backgrounds, but you can still use curated themes.”

---

## 3) UX constraint: restricted prompt UI (MVP safety)
To reduce safety and policy risk, Lumen does NOT accept free-form prompts in MVP.

### 3.1 Prompt is composed from:
- `styleId` (Abstract, Nature, Mist, Minimal, Gradient-like)
- `colorFamily` (Warm/Cool/Mono)
- `mood` (Calm/Hopeful/Focused)
- `detailLevel` slider (maps to steps and prompt adjectives)

Example prompt template:
- “soft abstract watercolor clouds, calm atmosphere, warm palette, minimal, high quality, no people, no text”

Negative prompt template:
- “people, face, portrait, nude, violence, gore, weapon, blood, text, watermark, logo, explicit”

(Exact prompt strings should be curated by the product team and reviewed for policy risk.)

---

## 4) Generation pipeline

### 4.1 Inputs
- Template prompt + negative prompt
- Seed (random or user-set “lock seed” P2)
- Steps (default 20; scaled by device)
- Guidance scale (default 7.0)
- Output size: 512×512 (MVP), optionally 768×768 (P2)
- Safety mode: STRICT (default)

### 4.2 Outputs
- PNG image
- Metadata JSON (generator params + safety score)
- Thumbnail (for grid)

### 4.3 Process
1. Build prompt from structured selections.
2. Run diffusion model on-device.
3. Run post-processing:
   - Optional subtle blur to reduce artifacts under text
   - Compute text-contrast overlay parameters
4. Safety check:
   - If classifier flags unsafe (P1), discard and show “Try different style”.
5. Save image and metadata to ThemeRepository.

### 4.4 Cancellation
- Generation runs in an async task with cancellation tokens.
- If cancelled, delete partial files and free model resources.

---

## 5) Safety & moderation

### 5.1 Primary safety strategy (MVP)
- Restrict prompts to safe templates.
- Use negative prompt injection.
- Avoid people/portraits entirely.
- Provide reporting UI.

### 5.2 Optional on-device safety classifier (P1)
Add a lightweight classifier to detect:
- nudity/sexual content
- violence/gore
- hateful symbols (optional)
- text/logo presence (optional)

Implementation options:
- Use a small Core ML classifier trained on safe/unsafe dataset.
- Or leverage an available open-source NSFW model converted to Core ML (ensure licensing).

Behavior:
- If score > threshold: block save, show message, and log a local safety event.
- Provide “Try again” button with different seed.

### 5.3 Reporting & user controls
- User can “Report image” from My Themes.
- If backend exists: send report metadata (no image unless user opts in).
- If no backend: store local report log for support export.

---

## 6) Caching & storage strategy

### 6.1 Generated images
- Store in app group folder: `AppGroup/themes/generated/{themeId}.png`
- Keep thumbnail: `{themeId}_thumb.jpg`
- Cap storage to N images (default 50) for free users; premium unlimited (or higher cap).

### 6.2 Model cache
- Store model weights in `AppSupport/ml-models/{modelId}/`
- Provide “Remove downloaded model” action.

### 6.3 Eviction policy
- LRU eviction for generated themes (free tier).
- Never delete favorited themes unless user requests.

---

## 7) Performance budgets & tuning

### 7.1 Parameters by device tier (example)
- High tier: steps=25, size=512
- Mid tier: steps=20, size=512
- Low tier: disable generation or steps=12

### 7.2 Thermal/battery tuning
- If `ProcessInfo.thermalState >= serious`: reduce steps by 30% or block generation.
- If battery < 15% and not charging: warn user and default to lower steps.

---

## 8) Optional on-device personalization (P1+)

### 8.1 What to personalize (safe)
- Which categories/tags to show more often
- Time-of-day preference for reminders
- Tone preference

### 8.2 What NOT to personalize (MVP)
- Generating new affirmation text via LLM (safety + factuality risk)

### 8.3 Simple model approach
Start with heuristic weights, then upgrade to on-device model:
- Multi-armed bandit per category/tag (updates from likes/dislikes)
- Use Core ML for ranking if desired (logistic regression)

Data stays on device unless user opts into sync.

---

## 9) Developer API (service interfaces)

### 9.1 MLBackgroundService
- `func canGenerate() -> Bool`
- `func generate(request: BackgroundGenerationRequest) async throws -> GeneratedTheme`
- `func cancelCurrentGeneration()`

### 9.2 BackgroundGenerationRequest
- `styleId`
- `colorFamily`
- `mood`
- `detailLevel`
- `seed?`
- `outputSize`

### 9.3 GeneratedTheme
- `themeId`
- `imagePath`
- `thumbnailPath`
- `metadata`

---

## 10) Test plan (ML-specific)
- Unit tests for prompt composer (no forbidden tokens).
- Golden tests for metadata serialization.
- Integration test: generate image, ensure file exists, ensure readable overlay computed.
- Performance test: generation time on target devices.
- Safety test: classifier thresholds and block paths.
