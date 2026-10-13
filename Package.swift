// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoibuSessionReplay",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "NoibuSessionReplay",
            targets: ["NoibuSessionReplay", "coreKit", "NoibuSessionReplayKronosLink"]
        )
    ],
    dependencies: [
        // NTP clock sync, used by NoibuClockMonitor. The binary references it without embedding it.
        .package(url: "https://github.com/lyft/Kronos.git", from: "4.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "NoibuSessionReplay",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/1.1.3/NoibuSessionReplay.xcframework.zip",
            checksum: "11c915289ceff2061af77feb1f5e6a5ee938645579c4ea681f0e9c6a10365785"
        ),
        .binaryTarget(
            name: "coreKit",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/1.1.3/coreKit.xcframework.zip",
            checksum: "e3c97f02a19e183bd7cfc46caf358aca845e6eac548780010605b900b83dbd84"
        ),
        .target(
            name: "NoibuSessionReplayKronosLink",
            dependencies: [.product(name: "Kronos", package: "Kronos")],
            path: "Sources/NoibuSessionReplayKronosLink"
        )
    ]
)
