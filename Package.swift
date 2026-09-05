// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QenTerraDesignSystem",
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
            path: "packages/Sources/QenTerra/DesignTokens"
        ),
        .target(
            name: "QenTerraComponents",
            dependencies: ["QenTerraDesignTokens"],
            path: "packages/Sources/QenTerra/Components"
        ),
        .target(
            name: "QenTerraMediaComponents",
            dependencies: ["QenTerraComponents", "QenTerraDesignTokens"],
            path: "packages/Sources/QenTerra/MediaComponents",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "QenTerraDesignTokensTests",
            dependencies: ["QenTerraDesignTokens"],
            path: "packages/Tests/QenTerraDesignTokensTests"
        ),
        .testTarget(
            name: "QenTerraComponentsTests",
            dependencies: ["QenTerraComponents", "QenTerraDesignTokens"],
            path: "packages/Tests/QenTerraComponentsTests"
        ),
        .testTarget(
            name: "QenTerraComponentSnapshotTests",
            dependencies: ["QenTerraComponents", "QenTerraDesignTokens"],
            path: "packages/Tests/QenTerraComponentSnapshotTests",
            resources: [.copy("__Snapshots__")]
        ),
        .testTarget(
            name: "QenTerraMediaComponentsTests",
            dependencies: ["QenTerraMediaComponents", "QenTerraDesignTokens"],
            path: "packages/Tests/QenTerraMediaComponentsTests"
        ),
    ]
)
