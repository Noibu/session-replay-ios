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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.1/NoibuSessionReplay.xcframework.zip",
            checksum: "ae2cd01197f2c478cea800fbdd060fcc4713b66d1130d8bc70ba1fa6e736ac6f"
        )
    ]
)
