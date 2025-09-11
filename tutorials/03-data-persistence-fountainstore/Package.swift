// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FountainStore",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "FountainStore", targets: ["FountainStore"])
    ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/the-fountainai.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "FountainStore",
            dependencies: [.product(name: "FountainAIAdapters", package: "the-fountainai"),\n                .product(name: "FountainAICore", package: "the-fountainai"),\n                .product(name: "PersistAPI", package: "the-fountainai"),\n                .product(name: "FountainStoreClient", package: "the-fountainai")],
            path: ".",
            sources: ["main.swift", "Greeter.swift"]
        ),
        .testTarget(
            name: "FountainStoreTests",
            dependencies: ["FountainStore"],
            path: "Tests/FountainStoreTests"
        )
    ]
)
