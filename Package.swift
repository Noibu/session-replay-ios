// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoibuSessionReplay",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "NoibuSessionReplay",
            targets: ["NoibuSessionReplay", "coreKit"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "NoibuSessionReplay",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/1.0.0-rc.2/NoibuSessionReplay.xcframework.zip",
            checksum: "1b5fdea1558440712411d8f391a4cb0c71e169a52eec18cb3d090a490703d7bf"
        ),
        .binaryTarget(
            name: "coreKit",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/1.0.0-rc.2/coreKit.xcframework.zip",
            checksum: "723ea57e9285f5943efdeb87c2c63da6f2f5194729c52f1e8671a4d4c88ae8ec"
        )
    ]
)
