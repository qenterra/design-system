// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QenTerraPackages",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(name: "QenTerraDesignTokens", targets: ["QenTerraDesignTokens"]),
        .library(name: "QenTerraComponents", targets: ["QenTerraComponents"]),
    ],
    targets: [
        .target(name: "QenTerraDesignTokens"),
        .target(
            name: "QenTerraComponents",
            dependencies: ["QenTerraDesignTokens"]
        ),
        .testTarget(
            name: "QenTerraDesignTokensTests",
            dependencies: ["QenTerraDesignTokens"]
        ),
        .testTarget(
            name: "QenTerraComponentsTests",
            dependencies: ["QenTerraComponents", "QenTerraDesignTokens"]
        ),
    ]
)
