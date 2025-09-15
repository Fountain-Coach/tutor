// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "OpenAPI",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "OpenAPI", targets: ["OpenAPI"])
    ],
    targets: [
        .executableTarget(
            name: "OpenAPI",
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
