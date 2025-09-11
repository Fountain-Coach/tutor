// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HelloFountainAI",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "HelloFountainAI", targets: ["HelloFountainAI"])
    ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/the-fountainai.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "HelloFountainAI",
            dependencies: [.product(name: "FountainAIAdapters", package: "the-fountainai"),
                .product(name: "FountainAICore", package: "the-fountainai"),
                .product(name: "LLMGatewayAPI", package: "the-fountainai")],
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
