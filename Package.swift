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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.4-rc.5/NoibuSessionReplay.xcframework.zip",
            checksum: "9e390ce94da06857c2169186e4fb00f59353777ad15e2eba1a212b5fe204b4d9"
        ),
        .binaryTarget(
            name: "coreKit",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.4-rc.5/NoibuSessionReplay.xcframework.zip",
            checksum: "9e390ce94da06857c2169186e4fb00f59353777ad15e2eba1a212b5fe204b4d9"
        )
    ]
)
