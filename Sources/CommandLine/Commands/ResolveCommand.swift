import ArgumentParser
import BinaryDependencyManager
import Foundation
import Yams
import Utils

struct ResolveCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
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
    @Option(name: [.customLong("config"), .short], help: "Path to the configuration file")
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

        let configuration = try configurationReader
            .readConfiguration(at: configurationFilePath, currentToolVersion: BinaryDependenciesManager.version)

        self.configuration = configuration

        // Paths from CLI arguments take precedence over those from the configuration file.
        outputDirectoryPath = configurationReader
            .resolveOutputDirectoryURL(outputDirectoryPath ?? configuration.outputDirectory)
            .path(percentEncoded: false)
        cacheDirectoryPath = configurationReader
            .resolveCacheDirectoryURL(cacheDirectoryPath ?? configuration.cacheDirectory)
            .path(percentEncoded: false)

    }

    func run() throws {
        guard let configuration else {
            // Should never happen, because we validate the configuration in `validate()` method.
            throw GenericError("Configuration is not initialized")
        }
        guard let outputDirectoryPath else {
            // Should never happen, because we validate the configuration in `validate()` method.
            throw GenericError("Output directory path is not initialized")
        }
        guard let cacheDirectoryPath else {
            // Should never happen, because we validate the configuration in `validate()` method.
            throw GenericError("Cache directory path is not initialized")
        }

        let dependenciesResolver = DependenciesResolverRunner(
            dependencies: configuration.dependencies,
            outputDirectoryURL: outputDirectoryPath.asFileURL,
            cacheDirectoryURL: cacheDirectoryPath.asFileURL,
            dependenciesDownloader: try CLI.GitHub(),
            unarchiver: try CLI.Unzip(),
            checksumCalculator: SHA256ChecksumCalculator()
        )

        // Run the dependencies resolver.
        try dependenciesResolver.run()
    }
}
