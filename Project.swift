import ProjectDescription

let project = Project(
    name: "NalssiChanggo",
    targets: [
        .target(
            name: "NalssiChanggo",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.NalssiChanggo",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            buildableFolders: [
                "NalssiChanggo/Sources",
                "NalssiChanggo/Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "NalssiChanggoTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.NalssiChanggoTests",
            infoPlist: .default,
            buildableFolders: [
                "NalssiChanggo/Tests"
            ],
            dependencies: [.target(name: "NalssiChanggo")]
        ),
    ]
)
