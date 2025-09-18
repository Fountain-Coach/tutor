// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "CsoundStudio",
    platforms: [ .macOS(.v14) ],
    products: [ .executable(name: "CsoundStudio", targets: ["CsoundStudio"]) ],
    targets: [
        .executableTarget(
            name: "CsoundStudio",
            path: "Sources/CsoundStudio"
        ),
        .testTarget(
            name: "CsoundStudioTests",
            dependencies: ["CsoundStudio"],
            path: "Tests/CsoundStudioTests"
        )
    ]
)

