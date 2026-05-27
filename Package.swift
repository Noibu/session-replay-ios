// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoibuSessionReplay",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "NoibuSessionReplay",
            targets: ["NoibuSessionReplay"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "NoibuSessionReplay",
            url: "https://github.com/Noibu/session-replay-ios/releases/download/v0.1.4-rc.1/NoibuSessionReplay.xcframework.zip",
            checksum: "a28102c6ecf009ab765e2c15ec4a880032dbd88bc385734e3daa9a8806735ec7"
        )
    ]
)
