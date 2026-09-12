// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QenTerraDesignSystem",
    platforms: [
        .macOS("26.0"),
        .iOS(.v16),
    ],
    products: [
        .library(name: "QenTerraFoundation", targets: ["QenTerraFoundation"]),
        .library(name: "QenTerraAudioAnalysis", targets: ["QenTerraAudioAnalysis"]),
        .library(name: "QenTerraDesignTokens", targets: ["QenTerraDesignTokens"]),
        .library(name: "QenTerraComponents", targets: ["QenTerraComponents"]),
        .library(name: "QenTerraMediaComponents", targets: ["QenTerraMediaComponents"]),
    ],
    targets: [
        .target(
            name: "QenTerraFoundation",
            path: "packages/Sources/QenTerra/Foundation"
        ),
        .target(
            name: "QenTerraAudioAnalysis",
            path: "packages/Sources/QenTerra/AudioAnalysis"
        ),
        .testTarget(
            name: "QenTerraFoundationTests",
            dependencies: ["QenTerraFoundation"],
            path: "packages/Tests/QenTerraFoundationTests"
        ),
        .testTarget(
            name: "QenTerraAudioAnalysisTests",
            dependencies: ["QenTerraAudioAnalysis"],
            path: "packages/Tests/QenTerraAudioAnalysisTests"
        ),
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
            dependencies: ["QenTerraComponents", "QenTerraDesignTokens", "QenTerraMediaComponents"],
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
