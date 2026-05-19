// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Shared",
    defaultLocalization: "en",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "LMSCore", targets: ["LMSCore"]),
        .library(name: "LMSDesignSystem", targets: ["LMSDesignSystem"]),
    ],
    targets: [
        .target(name: "LMSCore"),
        .target(
            name: "LMSDesignSystem",
            dependencies: ["LMSCore"]
        ),
        .testTarget(name: "LMSCoreTests", dependencies: ["LMSCore"]),
        .testTarget(name: "LMSDesignSystemTests", dependencies: ["LMSDesignSystem"]),
    ]
)
