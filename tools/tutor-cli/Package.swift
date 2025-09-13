// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TutorCLI",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "tutor", targets: ["TutorCLI"])
    ],
    dependencies: [
        // Reuse FountainAI MIDI stack when available
        .package(url: "https://github.com/Fountain-Coach/the-fountainai.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "TutorCLI",
            dependencies: [
                .product(name: "SSEOverMIDI", package: "the-fountainai")
            ],
            linkerSettings: [
                .linkedFramework("CoreMIDI", .when(platforms: [.macOS]))
            ]
        )
    ]
)
