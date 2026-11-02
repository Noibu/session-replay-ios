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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/2.1.0/NoibuSessionReplay.xcframework.zip",
            checksum: "f04c80156d3f8cbc826a7427fac3d32c4cf9426dea638abb9426e11cad8f6b55"
        ),
        .binaryTarget(
            name: "coreKit",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/2.1.0/coreKit.xcframework.zip",
            checksum: "cbb7978a0db5a122d4aaa67e1f727318cbc609a02a816f02092c8e1d280ce64b"
        ),
        .target(
            name: "NoibuSessionReplayKronosLink",
            dependencies: [.product(name: "Kronos", package: "Kronos")],
            path: "Sources/NoibuSessionReplayKronosLink"
        )
    ]
)
