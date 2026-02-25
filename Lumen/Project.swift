import ProjectDescription

// MARK: - Constants

let teamId = "YUYU7763AG"
let bundleIdPrefix = "com.gragera"

// MARK: - Settings

let baseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6.2",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "DEVELOPMENT_TEAM": .string(teamId),
    "CODE_SIGN_STYLE": "Automatic",
]

// MARK: - Project

let project = Project(
    name: "Lumen",
    options: .options(
        defaultKnownRegions: ["en", "es"],
        developmentRegion: "en"
    ),
    settings: .settings(base: baseSettings),
    targets: [
        // MARK: - Lumen (iOS App)
        .target(
            name: "Lumen",
            destinations: .iOS,
            product: .app,
            bundleId: "\(bundleIdPrefix).lumen",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Lumen",
                "UILaunchScreen": [:],
                "UIAppFonts": [
                    "AbrilFatface-Regular.ttf",
                    "Caveat.ttf",
                    "CormorantGaramond-Bold.ttf",
                    "CormorantGaramond-SemiBold.ttf",
                    "DancingScript.ttf",
                    "JosefinSans.ttf",
                    "PlayfairDisplay.ttf",
                    "Righteous-Regular.ttf",
                    "ZillaSlab-Bold.ttf",
                    "ZillaSlab-SemiBold.ttf"
                ]
            ]),
            sources: [
                "App/**",
                "Extensions/**",
                "Features/**",
                "Models/**",
                "Navigation/**",
                "Services/**",
                "Theme/**",
            ],
            resources: [
                .glob(pattern: "Resources/**"),
            ],
            entitlements: .file(path: "Lumen.entitlements"),
            dependencies: [
                .target(name: "LumenWidgets"),
                .external(name: "RevenueCat"),
                .external(name: "RevenueCatUI"),
                .external(name: "Dependencies"),
            ],
            settings: .settings(base: [
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                "ENABLE_PREVIEWS": "YES",
            ])
        ),

        // MARK: - LumenWidgets (App Extension)
        .target(
            name: "LumenWidgets",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "\(bundleIdPrefix).lumen.widgets",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .file(path: "LumenWidgets/Info.plist"),
            sources: [
                "LumenWidgets/**",
                "Models/Enums/Tone.swift",
                "Models/Enums/ThemeType.swift",
                "Extensions/Color+Hex.swift",
                "Theme/Theme.swift",
                "Theme/Components/GradientBackground.swift",
                "Theme/Components/ReadabilityOverlay.swift",
            ],
            entitlements: .file(path: "LumenWidgets/LumenWidgets.entitlements"),
            settings: .settings(base: [
                "SKIP_INSTALL": "YES",
            ])
        ),

        // MARK: - LumenWatch (watchOS App)
        .target(
            name: "LumenWatch",
            destinations: [.appleWatch],
            product: .app,
            bundleId: "\(bundleIdPrefix).lumen.watchkitapp",
            deploymentTargets: .watchOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Lumen",
                "WKCompanionAppBundleIdentifier": "\(bundleIdPrefix).lumen",
            ]),
            sources: [
                "LumenWatch/**",
            ],
            entitlements: .file(path: "LumenWatch/LumenWatch.entitlements"),
            settings: .settings(base: [
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "SKIP_INSTALL": "YES",
            ])
        ),

        // MARK: - LumenTests (Unit Tests)
        .target(
            name: "LumenTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundleIdPrefix).lumen.tests",
            deploymentTargets: .iOS("26.0"),
            sources: [
                "Tests/**",
            ],
            dependencies: [
                .target(name: "Lumen"),
                .external(name: "SnapshotTesting"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "Lumen",
            shared: true,
            buildAction: .buildAction(targets: ["Lumen", "LumenWidgets"]),
            testAction: .targets(
                [.testableTarget(target: "LumenTests")],
                configuration: .debug
            ),
            runAction: .runAction(configuration: .debug),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(configuration: .release),
            analyzeAction: .analyzeAction(configuration: .debug)
        ),
        .scheme(
            name: "LumenWatch",
            shared: true,
            buildAction: .buildAction(targets: ["LumenWatch"]),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
