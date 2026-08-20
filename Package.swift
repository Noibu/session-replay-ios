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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/1.0.0-rc.3/NoibuSessionReplay.xcframework.zip",
            checksum: "c8b968db75b380857ddc21606547dbe3209ab07af920ff3a06dbe147c7ba9497"
        ),
        .binaryTarget(
            name: "coreKit",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/1.0.0-rc.3/coreKit.xcframework.zip",
            checksum: "eadef985b6aec4de934c9266c44ef9faa496bb31fcc373ab8c29e0d576c8e254"
        )
    ]
)
