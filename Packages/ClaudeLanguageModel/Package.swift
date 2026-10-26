// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ClaudeLanguageModel",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "ClaudeLanguageModel", targets: ["ClaudeLanguageModel"]),
    ],
    targets: [
        .target(name: "ClaudeLanguageModel"),
        .testTarget(name: "ClaudeLanguageModelTests", dependencies: ["ClaudeLanguageModel"]),
    ]
)
