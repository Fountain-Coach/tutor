// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TutorCLI",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "tutor", targets: ["TutorCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/the-fountainai.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "TutorCLI",
            dependencies: [
                .product(name: "SSEOverMIDI", package: "the-fountainai")
            ],
            resources: [
                .process("OpenAPI")
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
