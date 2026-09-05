// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QenTerraCoreConsumer",
    platforms: [.macOS("26.0")],
    dependencies: [.package(path: "../public")],
    targets: [
        .executableTarget(
            name: "QenTerraCoreConsumer",
            dependencies: [
                .product(name: "QenTerraDesignTokens", package: "public"),
                .product(name: "QenTerraComponents", package: "public"),
            ]
        ),
    ]
)
