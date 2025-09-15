// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HelloFountainAI",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "HelloFountainAI", targets: ["HelloFountainAI"]),
        .executable(name: "HelloCsound", targets: ["HelloCsound"])
    ],
    targets: [
        .executableTarget(
            name: "HelloFountainAI",
            path: "Sources/HelloFountainAI"
        ),
        .executableTarget(
            name: "HelloCsound",
            path: "Sources/HelloCsound",
            resources: [
                .copy("hello.csd")
            ]
        ),
        .testTarget(
            name: "HelloCsoundTests",
            dependencies: ["HelloCsound"]
        )
    ]
)
