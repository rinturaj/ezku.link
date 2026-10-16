// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EzkuLink",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "EzkuLink"
        ),
        .testTarget(
            name: "EzkuLinkTests",
            dependencies: ["EzkuLink"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
