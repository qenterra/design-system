// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QenTerraUtilitiesConsumer",
    platforms: [.macOS("26.0")],
    dependencies: [.package(path: "../public")],
    targets: [
        .executableTarget(
            name: "QenTerraUtilitiesConsumer",
            dependencies: [
                .product(name: "QenTerraFoundation", package: "public"),
                .product(name: "QenTerraAudioAnalysis", package: "public"),
            ]
        ),
    ]
)
