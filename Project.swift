import ProjectDescription

let project = Project(
    name: "NalssiChanggo",
    organizationName: "andev",
    targets: [
        .target(
            name: "NalssiChanggo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.andev.nalssichanggo",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: [
                "Projects/App/Sources/**"
            ],
            resources: [
                "Projects/App/Resources/**"
            ],
            dependencies: [
                .target(name: "Core"),
                .target(name: "WeatherDomain"),
                .target(name: "WeatherData"),
                .target(name: "WeatherEnsemble"),
                .target(name: "Location"),
                .target(name: "DesignSystem")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "너의_TEAM_ID",
                    "CODE_SIGN_STYLE": "Automatic"
                ]
            )
        ),

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
