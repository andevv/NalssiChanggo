import ProjectDescription

private let appGroupId = "group.com.andev.nalssichanggo"
private let devTeam: SettingValue = "L3KYP426WW"

let project = Project(
    name: "NalssiChanggo",
    organizationName: "andev",
    targets: [

        // MARK: - App

        .target(
            name: "NalssiChanggo",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.andev.nalssichanggo",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "날씨창고",
                    "CFBundleDevelopmentRegion": "ko",
                    "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                    "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                    "ITSAppUsesNonExemptEncryption": false,
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
                    "UISupportedInterfaceOrientations~ipad": ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown"],
                    "UIUserInterfaceStyle": "Light",
                    // Location
                    "NSLocationWhenInUseUsageDescription": "날씨 정보를 제공하기 위해 현재 위치를 사용합니다.",
                    "NSLocationAlwaysAndWhenInUseUsageDescription": "백그라운드에서도 날씨 정보를 갱신하기 위해 위치를 사용합니다.",
                    // Push Notification & Background fetch
                    "UIBackgroundModes": ["remote-notification", "fetch"],
                ]
            ),
            sources: [
                "Projects/App/Sources/**",
                "Projects/Shared/Sources/**",
            ],
            resources: [
                "Projects/App/Resources/**"
            ],
            entitlements: .dictionary([
                // WeatherKit
                "com.apple.developer.weatherkit": .boolean(true),
                // Push Notification — 배포 시 "production"으로 변경
                "aps-environment": .string("production"),
                // App Groups — Widget과 데이터 공유
                "com.apple.security.application-groups": .array([.string(appGroupId)]),
            ]),
            scripts: [
                .post(
                    script: "\"${SRCROOT}/Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/run\"",
                    name: "Firebase Crashlytics dSYM Upload",
                    inputPaths: [
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}",
                        "${SRCROOT}/Projects/App/Resources/GoogleService-Info.plist",
                    ],
                    basedOnDependencyAnalysis: false
                ),
            ],
            dependencies: [
                .target(name: "NalssiChanggoWidget"),
                .target(name: "Core"),
                .target(name: "WeatherDomain"),
                .target(name: "WeatherData"),
                .target(name: "WeatherEnsemble"),
                .target(name: "Location"),
                .target(name: "DesignSystem"),
                .external(name: "FirebaseAnalytics"),
                .external(name: "FirebaseCrashlytics"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": devTeam,
                    "CODE_SIGN_STYLE": "Automatic",
                    "MARKETING_VERSION": "1.3.0",
                    "CURRENT_PROJECT_VERSION": "1",
                    "INFOPLIST_KEY_CFBundleDisplayName": "날씨창고",
                    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.weather",
                    // Firebase static 바이너리의 ObjC 클래스가 dead-strip되지 않도록 강제 링크
                    "OTHER_LDFLAGS": ["$(inherited)", "-ObjC"],
                ]
            )
        ),

        // MARK: - App Tests

        .target(
            name: "NalssiChanggoTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.andev.nalssichanggoTests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                "Projects/App/Tests/**"
            ],
            dependencies: [
                .target(name: "NalssiChanggo")
            ]
        ),

        // MARK: - Widget

        .target(
            name: "NalssiChanggoWidget",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.andev.nalssichanggo.widget",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "날씨창고",
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                ],
            ]),
            sources: [
                "Projects/Widget/Sources/**",
                "Projects/Shared/Sources/**",
            ],
            entitlements: .dictionary([
                "com.apple.developer.weatherkit": .boolean(true),
                "com.apple.security.application-groups": .array([.string(appGroupId)]),
            ]),
            dependencies: [
                .target(name: "Core"),
                .target(name: "WeatherDomain"),
                .target(name: "WeatherEnsemble"),
                .target(name: "WeatherData"),
                .target(name: "Location"),
                .target(name: "DesignSystem"),
                .sdk(name: "WeatherKit",   type: .framework, status: .required),
                .sdk(name: "CoreLocation", type: .framework, status: .required),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": devTeam,
                    "CODE_SIGN_STYLE": "Automatic",
                    "MARKETING_VERSION": "1.3.0",
                    "CURRENT_PROJECT_VERSION": "1",
                ]
            )
        ),

        // MARK: - Core

        .target(
            name: "Core",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.andev.nalssichanggo.core",
            deploymentTargets: .iOS("17.0"),
            sources: [
                "Projects/Core/Sources/**"
            ]
        ),

        // MARK: - DesignSystem

        .target(
            name: "DesignSystem",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.andev.nalssichanggo.designsystem",
            deploymentTargets: .iOS("17.0"),
            sources: [
                "Projects/DesignSystem/Sources/**"
            ],
            resources: [
                "Projects/DesignSystem/Resources/**"
            ]
        ),

        // MARK: - Location

        .target(
            name: "Location",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.andev.nalssichanggo.location",
            deploymentTargets: .iOS("17.0"),
            sources: [
                "Projects/Location/Sources/**"
            ],
            dependencies: [
                .target(name: "Core"),
                .sdk(name: "CoreLocation", type: .framework, status: .required),
            ]
        ),

        // MARK: - WeatherDomain

        .target(
            name: "WeatherDomain",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.andev.nalssichanggo.weatherdomain",
            deploymentTargets: .iOS("17.0"),
            sources: [
                "Projects/WeatherDomain/Sources/**"
            ]
        ),

        // MARK: - WeatherEnsemble

        .target(
            name: "WeatherEnsemble",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.andev.nalssichanggo.weatherensemble",
            deploymentTargets: .iOS("17.0"),
            sources: [
                "Projects/WeatherEnsemble/Sources/**"
            ],
            dependencies: [
                .target(name: "WeatherDomain")
            ]
        ),

        // MARK: - WeatherData

        .target(
            name: "WeatherData",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.andev.nalssichanggo.weatherdata",
            deploymentTargets: .iOS("17.0"),
            sources: [
                "Projects/WeatherData/Sources/**"
            ],
            dependencies: [
                .target(name: "Core"),
                .target(name: "Location"),
                .target(name: "WeatherDomain"),
                .target(name: "WeatherEnsemble"),
                .sdk(name: "WeatherKit", type: .framework, status: .required),
                .sdk(name: "CoreLocation", type: .framework, status: .required),
            ]
        )
    ]
)
