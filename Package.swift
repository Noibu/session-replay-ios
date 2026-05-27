// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoibuSessionReplay",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "NoibuSessionReplay",
            targets: ["NoibuSessionReplay"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "NoibuSessionReplay",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/v0.1.0-rc.2/NoibuSessionReplay.xcframework.zip",
            checksum: "3e30f8f34922db8654202b2a36686dedcc8f41c25cee73dc04b83d5b39814000"
        )
    ]
)
