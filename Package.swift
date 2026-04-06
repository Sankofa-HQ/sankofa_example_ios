// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SankofaExampleIOS",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // This tells Xcode to treat this package as a runnable App
        .executable(name: "SankofaExampleIOS", targets: ["SankofaExampleIOS"])
    ],
    dependencies: [
        // Local relative path to the Sankofa SDK
        .package(path: "../../sdks/sankofa_sdk_ios")
    ],
    targets: [
        .executableTarget(
            name: "SankofaExampleIOS",
            dependencies: [
                .product(name: "SankofaIOS", package: "SankofaIOS")
            ],
            path: "Sources/SankofaExampleIOS",
            // This is required for SwiftUI apps in a Package
            resources: [
                .process("Info.plist")
            ]
        )
    ]
)
