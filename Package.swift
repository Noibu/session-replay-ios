// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoibuSessionReplay",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "NoibuSessionReplay",
            targets: ["NoibuSessionReplay"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "NoibuSessionReplay",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/v0.1.4-rc.1/NoibuSessionReplay.xcframework.zip",
            checksum: "e1626eb6f3c00b6a357a8e25b8fbc4c6e26efd80464328dba10e1f6247ca8a12"
        )
    ]
)
