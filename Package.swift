// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Writely",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Writely", targets: ["Writely"])
    ],
    targets: [
        .executableTarget(
            name: "Writely",
            path: "Sources/Writely"
        )
    ]
)
