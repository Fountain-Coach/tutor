// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ScreenplayEditor",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "ScreenplayEditor", targets: ["ScreenplayEditor"])
    ],
    targets: [
        .executableTarget(
            name: "ScreenplayEditor",
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
