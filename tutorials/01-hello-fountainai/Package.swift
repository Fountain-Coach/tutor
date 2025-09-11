// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HelloFountainAI",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "HelloFountainAI", targets: ["HelloFountainAI"])
    ],
    targets: [
        .executableTarget(
            name: "HelloFountainAI",
            path: ".",
            sources: ["main.swift", "Greeter.swift"]
        ),
        .testTarget(
            name: "HelloFountainAITests",
            dependencies: ["HelloFountainAI"],
            path: "Tests/HelloFountainAITests"
        )
    ]
)
