// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

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

    swiftLanguageModes: [
        .v6
    ]
)
