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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/1.2.0/NoibuSessionReplay.xcframework.zip",
            checksum: "850aec07963e9a580005ed2c94ebd3a85cc22632c5057487ea05021d14d5bf4a"
        ),
        .binaryTarget(
            name: "coreKit",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/1.2.0/coreKit.xcframework.zip",
            checksum: "c8c3788358b6d70c67b29a10044a496a06190b5c1ab7998e64e9e967447eaf4b"
        ),
        .target(
            name: "NoibuSessionReplayKronosLink",
            dependencies: [.product(name: "Kronos", package: "Kronos")],
            path: "Sources/NoibuSessionReplayKronosLink"
        )
    ]
)
