// swift-tools-version: 5.10
import PackageDescription
let package = Package(name: "RenderKindle", platforms: [.macOS(.v14)], targets: [
    .executableTarget(name: "RenderKindle", resources: [.copy("Resources")])
])
