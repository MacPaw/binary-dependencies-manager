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
    @Option(name: .shortAndLong, help: "Path to the configuration file")
    var configurationFilePath: String?

    /// Path to the cache directory.
    @Option(name: .long, help: "Path to the cache directory")
    var cacheDirectoryPath: String?

    /// Path to the output directory.
    @Option(name: .long, help: "Path to the output directory, where downloaded dependencies will be placed")
    var outputDirectoryPath: String?

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
