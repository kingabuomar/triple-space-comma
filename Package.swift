// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TripleSpaceComma",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TripleSpaceComma", targets: ["TripleSpaceComma"])
    ],
    targets: [
        .target(name: "TripleSpaceCommaCore"),
        .executableTarget(
            name: "TripleSpaceComma",
            dependencies: ["TripleSpaceCommaCore"]
        )
    ]
)
