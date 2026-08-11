// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    // Keep this package dependency-free: it is the foundation consumed by apps.
    name: "QenTerraDesignTokens",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(name: "QenTerraDesignTokens", targets: ["QenTerraDesignTokens"]),
    ],
    targets: [
        .target(name: "QenTerraDesignTokens"),
        .executableTarget(
            name: "QDSContractCheck",
            dependencies: ["QenTerraDesignTokens"]
        ),
        .testTarget(
            name: "QenTerraDesignTokensTests",
            dependencies: ["QenTerraDesignTokens"]
        ),
    ]
)
