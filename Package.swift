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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/1.0.0-rc.1/NoibuSessionReplay.xcframework.zip",
            checksum: "af30256013402c094a5f8327539fbe4f07657e960c458c91f6725fd3d6897450"
        ),
        .binaryTarget(
            name: "coreKit",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/1.0.0-rc.1/coreKit.xcframework.zip",
            checksum: "2f22cbacb70b4002086fc57972402ffc77f236d2b78994c217abddbc8769cdae"
        )
    ]
)
