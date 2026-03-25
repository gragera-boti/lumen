# Lumen — Xcode Project Setup Guide

## Prerequisites
- Xcode 15.0+
- macOS Sonoma 14.0+
- Apple Developer account (for StoreKit, notifications, and App Groups)

---

## 1. Create the Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Configure:
   - **Product Name:** `Lumen`
   - **Team:** Your development team
   - **Organization Identifier:** `com.lumen` (or your own)
   - **Interface:** SwiftUI
   - **Storage:** SwiftData
   - **Language:** Swift
4. Save it inside the `Lumen/` directory (alongside the existing folders)

---

## 2. Remove Xcode's Generated Files

Xcode creates `LumenApp.swift` and `ContentView.swift` — delete them from the project since ours already exist in `App/`.

---

## 3. Add Source Files

1. In Xcode's Project Navigator, right-click the `Lumen` target group
2. **Add Files to "Lumen"** → select these folders (check **"Create groups"**, check **"Add to target: Lumen"**):
   - `App/`
   - `Theme/`
   - `Models/`
   - `Services/`
   - `Features/`
   - `Navigation/`
   - `Extensions/`
3. Add resource files the same way (ensure they're in **"Copy Bundle Resources"**):
   - `Resources/affirmations_en.json`
   - `Resources/categories_en.json`
   - `Resources/en.lproj/Localizable.strings`
   - `Resources/es.lproj/Localizable.strings`
4. Add `Info.plist` — set it in Build Settings → **Info.plist File** → `Lumen/Info.plist`

---

## 4. Add Widget Extension

1. **File → New → Target** → **Widget Extension**
2. Name: `LumenWidgets`
3. Uncheck "Include Configuration App Intent"
4. Delete the generated Swift file
5. Add `LumenWidgets/LumenWidgets.swift` to the **LumenWidgets** target
6. ⚠️ The widget file has its own `@main` — make sure Xcode doesn't conflict with the app's `@main`

---

## 5. Add Watch App (Optional — P1)

1. **File → New → Target** → **watchOS → App**
2. Name: `LumenWatch`
3. Delete generated files
4. Add files from `LumenWatch/`:
   - `LumenWatchApp.swift`
   - `WatchContentView.swift`
   - `WatchComplication.swift`
5. The Watch complication widget uses its own `Widget` — do **not** include it in the main widget bundle

---

## 6. Configure App Groups

Both the main app, widget, and watch app need a shared App Group to share data.

1. Select the **Lumen** target → **Signing & Capabilities** → **+ Capability** → **App Groups**
2. Add: `group.com.lumen.app`
3. Repeat for **LumenWidgets** target
4. Repeat for **LumenWatch** target (if added)

---

## 7. Build Settings

### Deployment Target
- **Lumen:** iOS 17.0
- **LumenWidgets:** iOS 17.0
- **LumenWatch:** watchOS 10.0

### Swift Settings
- **Swift Language Version:** Swift 6 (or 5.9 minimum)
- **Strict Concurrency Checking:** Complete
  - Build Settings → search "Strict Concurrency" → set to **Complete**

### Localization
1. Project settings → **Info** tab → **Localizations**
2. Add **English** and **Spanish**
3. Xcode should auto-detect the `.lproj` folders

---

## 8. Configure StoreKit (for testing)

1. **File → New → File** → **StoreKit Configuration File**
2. Name: `LumenProducts.storekit`
3. Add products:
   - `lumen.premium.monthly` — Auto-Renewable Subscription, $4.99/month
   - `lumen.premium.yearly` — Auto-Renewable Subscription, $29.99/year
   - `lumen.premium.lifetime` — Non-Consumable, $79.99
4. Create a subscription group: `Lumen Premium`
5. In scheme settings: **Run → Options → StoreKit Configuration** → select `LumenProducts.storekit`

---

## 9. URL Scheme (Deep Links)

Already configured in `Info.plist`:
- Scheme: `lumen`
- Routes: `lumen://affirmation/{id}`, `lumen://category/{id}`, `lumen://paywall`, etc.

Verify: Target → **Info** → **URL Types** should show `lumen` scheme.

---

## 10. First Run Checklist

After setup, build and run. On first launch:

- [ ] Bundled content loads (85+ affirmations, 13 categories, 6 themes)
- [ ] Onboarding flow appears (Welcome → Categories → Tone → Reminders)
- [ ] After onboarding, tab bar shows (For You, Explore, Favorites, Settings)
- [ ] Feed displays affirmation cards with gradient backgrounds
- [ ] Swipe navigates between cards
- [ ] Favorite, TTS, and Share actions work
- [ ] Explore shows category grid
- [ ] Settings screens all load
- [ ] Widget appears in widget gallery

---

## 11. Project Structure Reference

```
Lumen/
├── App/
│   ├── LumenApp.swift              ← @main entry point
│   └── ContentView.swift           ← Root navigation + onboarding gate
├── Theme/
│   ├── Theme.swift                 ← Design tokens
│   └── Components/                 ← PrimaryButton, GradientBackground, ReadabilityOverlay
├── Models/
│   ├── Affirmation.swift           ← @Model
│   ├── Category.swift              ← @Model
│   ├── Favorite.swift              ← @Model
│   ├── SeenEvent.swift             ← @Model
│   ├── Dislike.swift               ← @Model
│   ├── AppTheme.swift              ← @Model
│   ├── UserPreferences.swift       ← @Model (singleton)
│   ├── EntitlementState.swift      ← @Model (singleton)
│   └── Enums/                      ← Tone, Intensity, ContentFilters, etc.
├── Services/
│   ├── Protocols/                  ← All service contracts
│   └── Implementations/            ← All production implementations
├── Features/
│   ├── Onboarding/                 ← 4-step flow
│   ├── Feed/                       ← Swipeable card feed
│   ├── Explore/                    ← Category grid + category feeds
│   ├── Favorites/                  ← Saved affirmations
│   ├── Settings/                   ← All settings sub-screens
│   ├── Paywall/                    ← StoreKit 2 subscription
│   ├── ThemeGenerator/             ← ML background generation
│   ├── Crisis/                     ← Help & crisis resources
│   └── History/                    ← Recently viewed
├── Navigation/
│   ├── AppRouter.swift             ← Per-tab NavigationPath
│   └── DeepLinkHandler.swift       ← lumen:// URL scheme
├── Extensions/                     ← Color+Hex, Date+Formatting, String+Localization
├── Resources/
│   ├── affirmations_en.json        ← 2,000 curated affirmations
│   ├── categories_en.json          ← 13 categories
│   ├── en.lproj/Localizable.strings
│   └── es.lproj/Localizable.strings
├── LumenWidgets/                   ← WidgetKit extension (S/M/L)
├── LumenWatch/                     ← watchOS app + complications
├── Tests/
│   ├── ViewModelTests/             ← 7 test files
│   └── ServiceTests/               ← 6 test files
├── Info.plist
├── SETUP.md                        ← This file
├── CHANGELOG.md
└── Documentation.md
```

---

## Troubleshooting

### "Duplicate @main"
Make sure only `App/LumenApp.swift` has `@main` for the Lumen target. The widget and watch have their own `@main` in their respective targets.

### "Cannot find type 'Category' in scope"
Ensure all `Models/` files are added to the correct target. Watch and Widget targets should NOT include model files (they use shared JSON snapshots).

### Content not loading
Verify `affirmations_en.json` and `categories_en.json` appear in **Build Phases → Copy Bundle Resources** for the Lumen target.

### Widget not showing data
Check that App Group `group.com.lumen.app` is configured on both the main app and widget targets, and that the group identifier matches the string in `WidgetService.swift`.

### StoreKit products not appearing
Make sure the `.storekit` configuration file is selected in the scheme's Run options.
