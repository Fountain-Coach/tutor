// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TutorCLI",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "tutor", targets: ["TutorCLI"])
    ],
    targets: [
        .executableTarget(name: "TutorCLI")
    ]
)
