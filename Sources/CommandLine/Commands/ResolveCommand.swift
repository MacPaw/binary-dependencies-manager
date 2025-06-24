import ArgumentParser
import BinaryDependencyManager
import Foundation
import Yams
import Utils

struct ResolveCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "resolve",
        version: BinaryDependenciesManager.configuration.version
    )

    /// Path to the configuration file.
    ///
    /// Example:
    /// ```
    /// $ binary-dependencies-manager resolve --config ./.binary-dependencies.yaml
    /// $ binary-dependencies-manager resolve -c ./.binary-dependencies.yaml
    /// ```
    @Option(name: [.customLong("config", withSingleDash: true), .short], help: "Path to the configuration file")
    var configurationFilePath: String?

    /// Path to the output directory.
    ///
    /// Example:
    /// ```
    /// $ binary-dependencies-manager resolve --output ./output
    /// $ binary-dependencies-manager resolve -o ./output
    /// ```
    @Option(name: [.customLong("output"), .short], help: "Path to the output directory, where downloaded dependencies will be placed")
    var outputDirectoryPath: String?

    /// Path to the cache directory.
    ///
    /// Example:
    /// ```
    /// $ binary-dependencies-manager resolve --cache ./cache
    /// ```
    @Option(name: [.customLong("cache")], help: "Path to the cache directory")
    var cacheDirectoryPath: String?

    /// Dependencies to resolve.
    var configuration: BinaryDependenciesConfiguration?

    /// Validates a given configuration file.
    mutating func validate() throws {
        let configurationReader: BinaryDependenciesConfigurationReader = .init()
        configuration = try configurationReader
            .readConfiguration(at: configurationFilePath, currentToolVersion: BinaryDependenciesManager.version)
        outputDirectoryPath = configurationReader
            .resolveOutputDirectoryURL(outputDirectoryPath ?? configuration?.outputDirectory)
            .path
        cacheDirectoryPath = configurationReader
            .resolveCacheDirectoryURL(cacheDirectoryPath ?? configuration?.cacheDirectory)
            .path
    }

    func run() throws {
        let resolver = DependenciesResolverRunner(
            dependencies: configuration!.dependencies,
            cacheDirectoryPath: cacheDirectoryPath!,
            outputDirectoryPath: outputDirectoryPath!
        )
        try resolver.run()
    }
}
