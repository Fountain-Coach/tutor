// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HelloCsound",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "HelloCsound", targets: ["HelloCsound"])
    ],
    targets: [
        .executableTarget(name: "HelloCsound", resources: [.copy("hello.csd")]),
        .testTarget(
            name: "HelloCsoundTests",
            dependencies: ["HelloCsound"],
            path: "Tests/HelloCsoundTests"
        )
    ]
)
