// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TutorialFountainStore",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "TutorialFountainStore", targets: ["TutorialFountainStore"])
    ],
    targets: [
        .executableTarget(
            name: "TutorialFountainStore",
            path: ".",
            sources: ["main.swift", "Greeter.swift", "FountainStore.swift"]
        ),
        .testTarget(
            name: "TutorialFountainStoreTests",
            dependencies: ["TutorialFountainStore"],
            path: "Tests/FountainStoreTests"
        )
    ]
)
