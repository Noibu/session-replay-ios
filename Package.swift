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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.3/NoibuSessionReplay.xcframework.zip",
            checksum: "f815ce3f45b8326a8049921a134b547aeab603f92e8dffd65e51f991c8449f25"
        )
    ]
)
