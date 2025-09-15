// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "BasicTeatro",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "BasicTeatro", targets: ["BasicTeatro"])
    ],
    targets: [
        .executableTarget(name: "BasicTeatro"),
        .testTarget(
            name: "BasicTeatroTests",
            dependencies: ["BasicTeatro"],
            path: "Tests/BasicTeatroTests"
        )
    ]
)
