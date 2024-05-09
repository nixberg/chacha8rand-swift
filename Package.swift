// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "chacha8rand-swift",
    products: [
        .library(
            name: "ChaCha8Rand",
            targets: ["ChaCha8Rand"]),
    ],
    targets: [
        .target(
            name: "ChaCha8Rand"),
        .testTarget(
            name: "ChaCha8RandTests",
            dependencies: ["ChaCha8Rand"]),
    ]
)
