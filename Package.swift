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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.0-rc.2-SNAPSHOT/NoibuSessionReplay.xcframework.zip",
            checksum: "213c59f95cb542fa6c6a37eda01fed23d1088f237cd6df44c0f0e8b37a861ea1"
        ),
        .binaryTarget(
            name: "coreKit",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.0-rc.2-SNAPSHOT/coreKit.xcframework.zip",
            checksum: "1993efa8eebd0ab3ac85d253f6d5aa3f6c03909861826e41d505804117f17435"
        )
    ]
)
