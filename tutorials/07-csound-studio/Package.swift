// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "CsoundStudio",
    platforms: [ .macOS(.v14) ],
    products: [
        .library(name: "CsoundStudioCore", targets: ["CsoundStudioCore"]),
        .executable(name: "CsoundStudio", targets: ["CsoundStudio"])
    ],
    targets: [
        .target(
            name: "CsoundStudioCore",
            path: "Sources/CsoundStudioCore"
        ),
        .executableTarget(
            name: "CsoundStudio",
            dependencies: ["CsoundStudioCore"],
            path: "Sources/CsoundStudio"
        ),
        .testTarget(
            name: "CsoundStudioTests",
            dependencies: ["CsoundStudioCore"],
            path: "Tests/CsoundStudioTests"
        )
    ]
)
