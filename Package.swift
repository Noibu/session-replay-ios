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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.4-rc.3/NoibuSessionReplay.xcframework.zip",
            checksum: "e0aa26cfa31c458fdc39c7eb1d5eed6a70f1a42fa17e18434a107996a23ac574"
        )
    ]
)
