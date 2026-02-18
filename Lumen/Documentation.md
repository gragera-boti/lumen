# Lumen — Documentation

## Architecture

MVVM + Services following AGENTS.md guidelines:
- **iOS 17+**, Swift 6, SwiftUI, SwiftData
- No third-party dependencies
- Protocol-based DI via initializer injection

## Project Structure

```
Lumen/
├── App/                          # @main entry + ContentView
├── Theme/                        # Design tokens + reusable components
├── Models/                       # SwiftData @Model types
│   └── Enums/                    # Value types (Tone, Intensity, etc.)
├── Services/
│   ├── Protocols/                # Service contracts
│   └── Implementations/         # Production implementations
├── Features/
│   ├── Onboarding/              # 4-step first-run flow
│   ├── Feed/                    # Main affirmation swipe feed
│   ├── Explore/                 # Category grid + category feeds
│   ├── Favorites/               # Saved affirmations list
│   ├── Settings/                # All settings sub-screens
│   ├── Paywall/                 # StoreKit 2 subscription
│   ├── ThemeGenerator/          # Background generation UI
│   └── Crisis/                  # Help & crisis resources
├── Navigation/                  # AppRouter + DeepLinkHandler
├── Extensions/                  # Color+Hex, Date+Formatting
├── Resources/                   # Bundled JSON content packs
├── LumenWidgets/                # WidgetKit extension
└── Tests/                       # Unit tests
```

## Navigation

- Tab-based: For You, Explore, Favorites, Settings
- Per-tab `NavigationPath` managed by `AppRouter`
- All destinations in `AppDestination` enum
- Deep links via `lumen://` URL scheme

## Services

| Service | Protocol | Responsibility |
|---------|----------|---------------|
| ContentService | ContentServiceProtocol | Load bundled JSON, fetch categories/affirmations |
| FeedService | FeedServiceProtocol | Weighted feed algorithm, daily affirmation, seen tracking |
| FavoriteService | FavoriteServiceProtocol | Toggle/fetch favorites |
| PreferencesService | PreferencesServiceProtocol | User preferences CRUD |
| SpeechService | SpeechServiceProtocol | AVSpeechSynthesizer TTS |
| NotificationService | NotificationServiceProtocol | Local notifications, permissions |
| EntitlementService | EntitlementServiceProtocol | StoreKit 2 purchases, entitlements |
| ShareService | ShareServiceProtocol | Render share images |
| WidgetService | — | Write widget snapshot JSON |

## Feed Algorithm

1. Query candidates by category, tone, gentle mode, sensitivity filters
2. Exclude recently seen (last 50) and disliked
3. Weighted random pick: tone match (×1.15), tag overlap with favorites (×0.08/tag), novelty boost
4. Relaxation cascade if no candidates: allow older seen → other tones → fallback categories

## Data Flow

1. App loads bundled `categories_en.json` + `affirmations_en.json` on first run
2. Content imported into SwiftData
3. Feed requests next card via `FeedService.nextAffirmation()`
4. Card rendered with gradient background from `LumenTheme.Colors.gradients`
5. Actions (favorite, seen, dislike) update SwiftData and persist

## Deep Link Routes

- `lumen://affirmation/{id}` → open specific affirmation
- `lumen://category/{id}` → open category feed
- `lumen://favorites` → switch to favorites tab
- `lumen://settings/reminders` → open reminders settings
- `lumen://paywall` → show paywall
- `lumen://help/crisis` → show crisis resources

## Widget

- Reads from App Group `widget_snapshot.json`
- Updated by `WidgetService` when daily affirmation changes
- Refreshes at midnight via timeline policy

## On-Device ML Background Generation

### Architecture
- `MLBackgroundServiceProtocol` — defines generate/cancel/download/delete
- `MLBackgroundService` — production implementation
- `ThemeGeneratorViewModel` — MVVM orchestration

### Pipeline
1. Device capability check (memory ≥ 4GB, thermal state OK)
2. Prompt composition from structured selections (no free-form text)
3. **MVP:** Procedural generation (gradient + noise + mood overlay)
4. **Production:** Core ML Stable Diffusion pipeline (commented integration point)
5. Safety: negative prompts always applied, no people/violence/explicit
6. Output saved to App Group as PNG + JPEG thumbnail

### Device Tiers
- **High** (≥8GB RAM): 25 steps
- **Mid** (≥6GB RAM): 20 steps
- **Low** (<6GB RAM): 12 steps

### Model Management
- Downloaded on-demand to Application Support
- SHA-256 checksum verification
- User can delete to free storage
- Graceful fallback to curated themes if unsupported

## Watch App

- Shared data via App Group (`watch_affirmations.json`)
- Current affirmation + Favorite + Next actions
- Complications: accessoryRectangular, accessoryInline, accessoryCorner
- Daily refresh via timeline policy
