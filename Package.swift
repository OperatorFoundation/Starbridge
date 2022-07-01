// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Starbridge",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "Starbridge",
            targets: ["Starbridge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/ReplicantSwift.git", branch: "main")
    ],
    targets: [
        .target(
            name: "Starbridge",
            dependencies: [
            "ReplicantSwift",
            ]),
        .testTarget(
            name: "StarbridgeTests",
            dependencies: ["Starbridge"]),
    ],
    swiftLanguageVersions: [.v5]
)
