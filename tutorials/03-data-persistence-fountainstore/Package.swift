// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TutorialFountainStore",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "TutorialFountainStore", targets: ["TutorialFountainStore"])
    ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/the-fountainai.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "TutorialFountainStore",
            dependencies: [
                .product(name: "FountainAIAdapters", package: "the-fountainai"),
                .product(name: "FountainAICore", package: "the-fountainai"),
                .product(name: "PersistAPI", package: "the-fountainai"),
                .product(name: "FountainStoreClient", package: "the-fountainai")
            ],
            path: ".",
            sources: ["main.swift", "Greeter.swift"]
        ),
        .testTarget(
            name: "TutorialFountainStoreTests",
            dependencies: ["TutorialFountainStore"],
            path: "Tests/FountainStoreTests"
        )
    ]
)
