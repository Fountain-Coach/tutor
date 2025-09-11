// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Midi2",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "Midi2", targets: ["Midi2"])
    ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/the-fountainai.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "Midi2",
            dependencies: [.product(name: "MIDI2Models", package: "the-fountainai"),\n                .product(name: "MIDI2Core", package: "the-fountainai"),\n                .product(name: "SSEOverMIDI", package: "the-fountainai"),\n                .product(name: "FlexBridge", package: "the-fountainai")],
            path: ".",
            sources: ["main.swift", "Greeter.swift"]
        ),
        .testTarget(
            name: "Midi2Tests",
            dependencies: ["Midi2"],
            path: "Tests/Midi2Tests"
        )
    ]
)
