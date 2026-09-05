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
    ]
)
