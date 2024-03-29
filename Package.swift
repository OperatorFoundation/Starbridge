// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Starbridge",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "Starbridge",
            targets: ["Starbridge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.5.4"),
        
        .package(url: "https://github.com/OperatorFoundation/Antiphony", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Gardener", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/KeychainTypes", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/ReplicantSwift", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionAsync", branch: "main"),
    ],
    targets: [
        .target(
            name: "Starbridge",
            dependencies: [
                "Antiphony",
                "KeychainTypes",
                "ReplicantSwift",
                "TransmissionAsync",
                .product(name: "Logging", package: "swift-log"),
            ]),
        .testTarget(
            name: "StarbridgeTests",
            dependencies: ["Starbridge"]),
    ],
    swiftLanguageVersions: [.v5]
)
