// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            // 실제 소스 코드가 있는 타겟만 dynamic framework으로 변환
            // FirebaseAnalytics / GoogleAppMeasurement 래퍼는 dummy.m만 있어서
            // static(기본값) 유지해야 binary XCFramework 코드가 앱에 링크됨
            "FirebaseCore": .framework,
            "FirebaseCoreInternal": .framework,
            "FirebaseInstallations": .framework,
            "FirebaseSessions": .framework,
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
