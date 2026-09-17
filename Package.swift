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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/1.1.0/NoibuSessionReplay.xcframework.zip",
            checksum: "da3d079a320385e280621c66feb77ef8c7a02d828b88a2b55b68e229f06b48fa"
        ),
        .binaryTarget(
            name: "coreKit",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/1.1.0/coreKit.xcframework.zip",
            checksum: "9d36a208b7b98852e5647f6f6501226cd200b9aa898219e5b107364d98329e7f"
        ),
        .target(
            name: "NoibuSessionReplayKronosLink",
            dependencies: [.product(name: "Kronos", package: "Kronos")],
            path: "Sources/NoibuSessionReplayKronosLink"
        )
    ]
)
