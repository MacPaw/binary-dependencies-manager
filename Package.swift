// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Not using 6.1 because CodeQL default runner for Swift is `macos-latest`.
// `macos-latest` is macOS 14 (Sonoma). Runner has Xcode 15.4 as default, Swift version 5.10.
// We can't select Xcode version for the default CodeQL checks.
// That's why we can't use swift-tools 6.0 or higher.
// Using 6.0 or higher would require to create a custom workflow for CodeQL checks.
//
// Quick links:
//  * GHA runners: https://docs.github.com/en/actions/how-tos/using-github-hosted-runners/using-github-hosted-runners/about-github-hosted-runners#standard-github-hosted-runners-for-public-repositories
//  * Images configs: https://github.com/actions/runner-images/tree/main/images/macos
//
// Checked: 2025-07-03.


import PackageDescription

let package = Package(
    name: "binary-dependencies-manager",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "binary-dependencies-manager",
            targets: ["CommandLine"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.5.1")),
        .package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "3.12.3")),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "6.0.1")),
    ],

    targets: [

        .executableTarget(
            name: "CommandLine",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "BinaryDependencyManager",
                "Utils",
            ]
        ),

        .target(
            name: "BinaryDependencyManager",
            dependencies: [
                "Utils",
                .product(name: "Yams", package: "Yams"),
            ]
        ),

        .target(
            name: "Utils",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),

        .testTarget(
            name: "BinaryDependencyManagerTests",
            dependencies: [
                .target(name: "BinaryDependencyManager"),
            ]
        ),

        .testTarget(
            name: "UtilsTests",
            dependencies: [
                .target(name: "Utils"),
            ]
        ),
    ],

    swiftLanguageVersions: [
        .v5,
        .version("6") // swift-tools 5.10 has no .v6 enum case yet.
    ]
)
