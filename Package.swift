// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "binary-dependencies-manager",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "binary-dependencies-manager",
            targets: ["CommandLine"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.5.1")),
        .package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "3.12.3")),
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
                .product(name: "Crypto", package: "swift-crypto"),
                "Utils"
            ]
        ),
        
        .target(name: "Utils"),

        .testTarget(
            name: "BinaryDependencyManagerTests",
            dependencies: [
                .target(name: "BinaryDependencyManager")
            ]
        ),
    ]
)
