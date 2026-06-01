// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "FirebaseAnalytics": .framework,
            "FirebaseCore": .framework,
            "FirebaseCoreInternal": .framework,
            "FirebaseInstallations": .framework,
            "FirebaseSessions": .framework,
            "GoogleAppMeasurement": .framework,
            "GoogleDataTransport": .framework,
            "GoogleUtilities": .framework,
            "GoogleUtilities-AppDelegateSwizzler": .framework,
            "GoogleUtilities-Environment": .framework,
            "GoogleUtilities-Logger": .framework,
            "GoogleUtilities-MethodSwizzler": .framework,
            "GoogleUtilities-NSData": .framework,
            "GoogleUtilities-Network": .framework,
            "GoogleUtilities-Reachability": .framework,
            "FirebaseCrashlytics": .framework,
            "FBLPromises": .framework,
            "GoogleUtilities-UserDefaults": .framework,
            "nanopb": .framework,
        ]
    )
#endif

let package = Package(
    name: "NalssiChanggo",
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.0.0"),
    ]
)
