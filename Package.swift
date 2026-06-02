// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NativeArkiv",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ArkivMac", targets: ["ArkivMac"])
    ],
    targets: [
        .executableTarget(name: "ArkivMac")
    ]
)
