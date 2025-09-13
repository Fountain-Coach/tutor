// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TutorTeatroViewer",
    platforms: [ .macOS(.v14) ],
    products: [ .executable(name: "teatro-viewer", targets: ["TeatroViewer"]) ],
    targets: [ .executableTarget(name: "TeatroViewer") ]
)

