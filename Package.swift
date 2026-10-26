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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/2.0.0/NoibuSessionReplay.xcframework.zip",
            checksum: "09ec080f4fded183e931ad5aa5a0143629f03ee07dccf8c3b9580cea4dd530f2"
        ),
        .binaryTarget(
            name: "coreKit",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/2.0.0/coreKit.xcframework.zip",
            checksum: "464b9d8192ebaad285afd2f325076bc26a66ba25fa0510cb61bb2f293f5ee23d"
        ),
        .target(
            name: "NoibuSessionReplayKronosLink",
            dependencies: [.product(name: "Kronos", package: "Kronos")],
            path: "Sources/NoibuSessionReplayKronosLink"
        )
    ]
)
