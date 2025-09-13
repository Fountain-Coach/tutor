// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TutorCLI",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "tutor", targets: ["TutorCLI"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TutorCLI",
            dependencies: [],
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
