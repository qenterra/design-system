// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QenTerraPackages",
    platforms: [
        .macOS("26.0"),
        .iOS(.v16),
    ],
    products: [
        .library(name: "QenTerraDesignTokens", targets: ["QenTerraDesignTokens"]),
        .library(name: "QenTerraComponents", targets: ["QenTerraComponents"]),
        .library(name: "QenTerraMediaComponents", targets: ["QenTerraMediaComponents"]),
    ],
    targets: [
        .target(
            name: "QenTerraDesignTokens",
            path: "Sources/QenTerra/DesignTokens"
        ),
        .target(
            name: "QenTerraComponents",
            dependencies: ["QenTerraDesignTokens"],
            path: "Sources/QenTerra/Components"
        ),
        .target(
            name: "QenTerraMediaComponents",
            dependencies: ["QenTerraComponents", "QenTerraDesignTokens"],
            path: "Sources/QenTerra/MediaComponents",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "QenTerraDesignTokensTests",
            dependencies: ["QenTerraDesignTokens"]
        ),
        .testTarget(
            name: "QenTerraComponentsTests",
            dependencies: ["QenTerraComponents", "QenTerraDesignTokens"]
        ),
        .testTarget(
            name: "QenTerraComponentSnapshotTests",
            dependencies: ["QenTerraComponents", "QenTerraDesignTokens"],
            resources: [.copy("__Snapshots__")]
        ),
        .testTarget(
            name: "QenTerraMediaComponentsTests",
            dependencies: ["QenTerraMediaComponents", "QenTerraDesignTokens"]
        ),
    ]
)
