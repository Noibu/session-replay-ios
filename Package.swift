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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.0-rc.1-SNAPSHOT/NoibuSessionReplay.xcframework.zip",
            checksum: "47d6facd2ce37ba03f741e7c68b65cb1c56ed3994766c942367d039c97de0932"
        ),
        .binaryTarget(
            name: "coreKit",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.0-rc.1-SNAPSHOT/coreKit.xcframework.zip",
            checksum: "141a1e3c29ff2fc4f5f62a429e8d6c5e89ebaf3233c24d45466dbff05778c9c2"
        )
    ]
)
