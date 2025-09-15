// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Midi2",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "Midi2", targets: ["Midi2"])
    ],
    targets: [
        .executableTarget(
            name: "Midi2",
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
