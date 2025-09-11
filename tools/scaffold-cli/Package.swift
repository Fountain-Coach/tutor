// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ScaffoldCLI",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "scaffold-cli", targets: ["ScaffoldCLI"])
    ],
    targets: [
        .executableTarget(name: "ScaffoldCLI")
    ]
)

