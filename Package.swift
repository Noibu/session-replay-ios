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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.0-rc.1/NoibuSessionReplay.xcframework.zip",
            checksum: "26476ca66d568b423c6f0aa9a5e6528a27aea7e6273b3f1b812ca0914f664941"
        )
    ]
)
