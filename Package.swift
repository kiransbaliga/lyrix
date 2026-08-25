// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Lyrix",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Lyrix",
            path: "Sources/Lyrix",
            exclude: ["Resources/Info.plist"]
        )
    ]
)
