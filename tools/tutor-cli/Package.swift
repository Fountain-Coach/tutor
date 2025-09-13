// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TutorCLI",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "tutor", targets: ["TutorCLI"])
    ],
    dependencies: [
        // Prefer local checkout if present to avoid network in tests
        .package(path: "../_deps/the-fountainai")
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
        ),
        .testTarget(
            name: "TutorCLITests",
            dependencies: ["TutorCLI"],
            path: "Tests/TutorCLITests"
        )
    ]
)
