// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "OpenAPI",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "OpenAPI", targets: ["OpenAPI"])
    ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/the-fountainai.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "OpenAPI",
            dependencies: [.product(name: "FountainAIAdapters", package: "the-fountainai"),\n                .product(name: "FountainAICore", package: "the-fountainai"),\n                .product(name: "LLMGatewayAPI", package: "the-fountainai")],
            path: ".",
            sources: ["main.swift", "Greeter.swift"]
        ),
        .testTarget(
            name: "OpenAPITests",
            dependencies: ["OpenAPI"],
            path: "Tests/OpenAPITests"
        )
    ]
)
