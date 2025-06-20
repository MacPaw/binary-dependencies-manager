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
            targets: ["BinaryDependenciesManager"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.5.1")),
        .package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "3.12.3")),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "6.0.1")),
    ],

    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "BinaryDependenciesManager",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),

        .testTarget(
            name: "DependenciesResolverTests",
            dependencies: ["BinaryDependenciesManager"]
        ),
    ]
)
