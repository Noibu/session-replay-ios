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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.4-rc.4/NoibuSessionReplay.xcframework.zip",
            checksum: "f94cb74a94359cfafa8fe98410616cf14c9b3ad070eae7a8f9bc95d1023b59dc"
        )
    ]
)
