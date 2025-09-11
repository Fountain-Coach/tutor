// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ScreenplayEditor",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "ScreenplayEditor", targets: ["ScreenplayEditor"])
    ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/the-fountainai.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "ScreenplayEditor",
            dependencies: [.product(name: "FountainAIAdapters", package: "the-fountainai"),\n                .product(name: "FountainAICore", package: "the-fountainai"),\n                .product(name: "LLMGatewayAPI", package: "the-fountainai"),\n                .product(name: "PersistAPI", package: "the-fountainai"),\n                .product(name: "FountainStoreClient", package: "the-fountainai"),\n                .product(name: "MIDI2Models", package: "the-fountainai"),\n                .product(name: "MIDI2Core", package: "the-fountainai"),\n                .product(name: "SSEOverMIDI", package: "the-fountainai"),\n                .product(name: "FlexBridge", package: "the-fountainai")],
            path: ".",
            sources: ["main.swift", "Greeter.swift"]
        ),
        .testTarget(
            name: "ScreenplayEditorTests",
            dependencies: ["ScreenplayEditor"],
            path: "Tests/ScreenplayEditorTests"
        )
    ]
)
