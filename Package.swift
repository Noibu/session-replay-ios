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
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.4-rc.6/NoibuSessionReplay.xcframework.zip",
            checksum: "5b2c8d19d36f2f667128ecf04b63b5984bf89a316807e0d884de31e1114e882d"
        ),
        .binaryTarget(
            name: "coreKit",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/0.1.4-rc.6/coreKit.xcframework.zip",
            checksum: "17f837155575843b75852be9cda19b97530e7696dd3b7987db093d0dc16afc8a"
        )
    ]
)
