import ArgumentParser
import Foundation
import Utils
import BinaryDependencyManager

struct CleanCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "clean")

    /// Path to the output directory.
    ///
    /// Example:
    /// ```
    /// $ binary-dependencies-manager clean --output ./output
    /// $ binary-dependencies-manager clean -o ./output
    /// ```
    @Option(name: [.customLong("output"), .short], help: "Path to the output directory, where downloaded dependencies will be placed")
    var outputDirectoryPath: String?

    /// Path to the cache directory.
    ///
    /// Example:
    /// ```
    /// $ binary-dependencies-manager clean --cache ./cache
    /// ```
    @Option(name: [.customLong("cache")], help: "Path to the cache directory")
    var cacheDirectoryPath: String?

    /// Validates a given configuration file.
    mutating func validate() throws {
        let configurationReader: BinaryDependenciesConfigurationReader = .init()

        outputDirectoryPath = configurationReader
            .resolveOutputDirectoryURL(outputDirectoryPath)
            .path(percentEncoded: false)
        cacheDirectoryPath = configurationReader
            .resolveCacheDirectoryURL(cacheDirectoryPath)
            .path(percentEncoded: false)
    }

    func run() throws {

        if let outputDirectoryPath {
            Logger.log("#Cleanup# Removing \(outputDirectoryPath)")
            try? FileManager.default.removeItem(at: outputDirectoryPath.asFileURL)
        }

        if let cacheDirectoryPath {
            Logger.log("#Cleanup# Removing \(cacheDirectoryPath)")
            try? FileManager.default.removeItem(at: cacheDirectoryPath.asFileURL)
        }
    }
}
