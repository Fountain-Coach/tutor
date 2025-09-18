// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "CsoundStudio",
    platforms: [ .macOS(.v14) ],
    products: [ .executable(name: "CsoundStudio", targets: ["CsoundStudio"]) ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/toolsmith.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "CsoundStudio",
            dependencies: [
                .product(name: "SandboxRunner", package: "toolsmith")
            ],
            path: "Sources/CsoundStudio"
        ),
        .testTarget(
            name: "CsoundStudioTests",
            dependencies: ["CsoundStudio"],
            path: "Tests/CsoundStudioTests"
        )
    ]
)
