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
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.andev.nalssichanggo",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
                    "UIUserInterfaceStyle": "Light",
                    // Location
                    "NSLocationWhenInUseUsageDescription": "날씨 정보를 제공하기 위해 현재 위치를 사용합니다.",
                    "NSLocationAlwaysAndWhenInUseUsageDescription": "백그라운드에서도 날씨 정보를 갱신하기 위해 위치를 사용합니다.",
                    // Push Notification & Background fetch
                    "UIBackgroundModes": ["remote-notification", "fetch"],
                ]
            ),
            sources: [
                "Projects/App/Sources/**"
            ],
            resources: [
                "Projects/App/Resources/**"
            ],
            entitlements: .dictionary([
                // WeatherKit
                "com.apple.developer.weatherkit": .boolean(true),
                // Push Notification — 배포 시 "production"으로 변경
                "aps-environment": .string("development"),
                // App Groups — Widget과 데이터 공유
                "com.apple.security.application-groups": .array([.string(appGroupId)]),
            ]),
            dependencies: [
                .target(name: "NalssiChanggoWidget"),
                .target(name: "Core"),
                .target(name: "WeatherDomain"),
                .target(name: "WeatherData"),
                .target(name: "WeatherEnsemble"),
                .target(name: "Location"),
                .target(name: "DesignSystem"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": devTeam,
                    "CODE_SIGN_STYLE": "Automatic",
                    "MARKETING_VERSION": "1.0",
                    "CURRENT_PROJECT_VERSION": "1",
                    "INFOPLIST_KEY_CFBundleDisplayName": "날씨창고",
                    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.weather",
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
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                ],
            ]),
            sources: [
                "Projects/Widget/Sources/**"
            ],
            entitlements: .dictionary([
                "com.apple.developer.weatherkit": .boolean(true),
                "com.apple.security.application-groups": .array([.string(appGroupId)]),
            ]),
            dependencies: [
                .target(name: "WeatherDomain"),
                .target(name: "DesignSystem"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": devTeam,
                    "CODE_SIGN_STYLE": "Automatic",
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
                .target(name: "Core")
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
                .target(name: "WeatherEnsemble")
            ]
        )
    ]
)
