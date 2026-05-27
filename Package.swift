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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.4-rc.2/NoibuSessionReplay.xcframework.zip",
            checksum: "3ff971989b615d4eafc37cedb7dc6c09444738392786cc2c1e6e96ba17195fe0"
        )
    ]
)
