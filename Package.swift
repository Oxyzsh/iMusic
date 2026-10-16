// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "iMusic",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "iMusic", targets: ["iMusic"])
    ],
    targets: [
        .executableTarget(
            name: "iMusic",
            path: "Sources/iMusic"
        )
    ]
)
