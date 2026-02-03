// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "McWritely",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "McWritely", targets: ["McWritely"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "McWritely",
            path: "Sources/McWritely"
        ),
        .testTarget(
            name: "McWritelyTests",
            dependencies: ["McWritely"]
        )
    ]
)
