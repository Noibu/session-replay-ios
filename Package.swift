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
            checksum: "ca9e0c94bd48a7c9b39439a915a2b727d0ef9445ed92c890df285c355b94d34f"
        )
    ]
)
