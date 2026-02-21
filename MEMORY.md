# MEMORY.md

## 2025-07-17
- First boot. Named myself Kit. 🛠️
- Human: Alberto, based in Spain (Europe/Madrid)
- Role: Senior iOS Engineer agent — Swift, SwiftUI, SwiftData
- Alberto prefers self-directed agents, minimal hand-holding

### Project: Lumen (Daily Affirmations App)
- Full spec provided by Alberto (38 files in ZIP)
- MVP built: 71 Swift files — models, services, features, widgets, tests
- Stack: SwiftData (not GRDB), MVVM + Services, iOS 17+, Swift 6
- Second pass: expanded to 92 Swift files, 11 test files, 85 affirmations, Watch app, en/es localization
- Third pass: procedural background generator (replaced initial ML/SD approach)
- Now at 101 Swift files, 15 test files, ~7,053 lines
- Content sub-agent spawned to generate 2,000+ affirmations
- Pending: Xcode project file (.xcodeproj), content delivery from sub-agent
- **COMPLETE**: 2,000 affirmations delivered, SETUP.md written, all MVP features implemented
- Pending only: .xcodeproj creation (manual in Xcode), App Store Connect

## 2026-02-18
- Resumed after ~7 months. Fixed missing `GeneratorStyle`/`ColorFamily` enum declarations
- Added `WidgetServiceProtocol`, `HistoryViewModelTests`, `CategoryFeedViewModelTests`
- Fixed missing `GeneratorStyle`/`ColorFamily` enum declarations
- Added `WidgetServiceProtocol`, `HistoryViewModelTests`, `CategoryFeedViewModelTests`
- Wired `.localized` across all views — 150+ keys, en + es fully covered
- Final count: 101 Swift files, 15 test files, ~7,200 lines
- Project is **fully code-complete** for MVP
- Xcode project generated via XcodeGen, builds clean on iPhone 17 Pro sim
- Bundle IDs: `com.gragera.lumen` (app), `.widgets`, `.watchkitapp`; App Group `group.com.gragera.lumen`
- ASC: App ID `6759335243`, API Key ID `54GDX3ZRZU`, Issuer `8da56372-26b9-474a-a426-c691338169a5`
- .p8 key NOT stored on disk — Alberto must re-provide when needed

### RevenueCat Integration
- RC Project: **Lumen** (ID: `a3542b61`)
- RC Account: alberto.gragera@gmail.com
- Test API Key: `test_BfhHUNuNlDTmWzMFOCKXfniuZkA`
- Entitlement: **"Lumen Pro"** (ID: `entld626a6d75d`)
- Products: Monthly (`monthly`), Yearly (`yearly`), Lifetime (`lifetime`) — all Test Store
- Default offering: `ofrng3eee650127` with 3 packages
- SDK: RevenueCat + RevenueCatUI via SPM (`purchases-ios-spm` v5.59.2)
- Paywall: Uses `RevenueCatUI.PaywallView()` (renamed ours to `LumenPaywallView`)
- **DONE**: IAP products created in ASC via API (using Mise key 7LBYRCA3YG)
- **PENDING**: Set Monthly ($3.99) and Yearly ($19.99) subscription prices (API returns 500, needs browser)
- **DONE**: Lifetime price set at $49.99 via API
- **PENDING**: Upload IAP .p8 + ASC API .p8 keys to RevenueCat dashboard
- **PENDING**: Update RC product IDs from test to real (`lumen.premium.*`)
- **PENDING**: Swap test key to production Apple API key once ASC is connected
- ASC Subscription Group: "Lumen Pro" (ID: 21941237)
- ASC Monthly Sub ID: 6759404315, Yearly: 6759401344, Lifetime IAP: 6759401345
- Pro feature gates tightened: premium category paywall trigger
- Theme generator daily limit REMOVED — procedural generation fully free
- Generator overhauled: 12 styles, 14 palettes, 5 moods (840 combos)
- Feed: crossfade transitions, tap-to-navigate, no auto-advance
- Typography: 70% New York serif, killed thin/light weights
- Custom affirmations: 8 font styles, ML suggestions, auto-favorite, edit/delete
- Favorites tab: split "My Affirmations" + "Favorites" sections
- CloudKit sync hidden until entitlement configured (CKContainer.default() crash fix)
- AffirmationFontStyle enum + fontStyle field added to Affirmation model
