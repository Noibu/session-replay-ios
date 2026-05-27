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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.4-rc.1/NoibuSessionReplay.xcframework.zip",
            checksum: "242fe1cbc6dc431cbecdf68a7f8ecd595edf57b847f334b5dbbd6b8efe864589"
        )
    ]
)
