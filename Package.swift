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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.2/NoibuSessionReplay.xcframework.zip",
            checksum: "72d97cccf6d10ad9c6d8d68b0ae043f72a7e29b6bee2422217eaa2ba3a9cfc01"
        )
    ]
)
