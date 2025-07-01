import Foundation
import Yams
import Utils

/// A utility for resolving and loading binary dependencies configuration files.
public struct BinaryDependenciesConfigurationReader {
    private static let defaultConfigurationFilenames: [String] = [
        ".binary-dependencies.yaml",
        ".binary-dependencies.yml",
        "Dependencies.json" // CMM, Setapp
    ]

    private static let defaultOutputDirectoryPaths: [String] = [
        "Dependencies/Binary",
        "Dependencies", // CMM, Setapp
    ]

    private static let defaultCacheDirectoryPaths: [String] = [
        ".cache/binary-dependencies",
        ".cache/dependencies", // Setapp
        ".dependencies-cache", // CMM
    ]

    private let fileManager: FileManagerProtocol

    public init(fileManager: FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    /// Resolves the file path based on the provided path, or searches through the specified variations.
    /// - Parameters:
    ///   - filePath: The path to resolve, or nil to search through variations.
    ///   - variations: A list of possible filenames or directory names to check if filePath is nil.
    /// - Returns: The resolved file URL. Crashes if no path is found.
    private func resolveFilePath(_ filePath: String?, variations: [String]) -> URL {
        let existingFileURL: URL? = filePath.map(\.asFileURL)
        guard existingFileURL == .none else { return existingFileURL! }

        let fileURL = (variations.first(where: fileManager.fileExists(atPath:)) ?? variations.first).map(\.asFileURL)

        guard let fileURL else {
            preconditionFailure("Path must be always resolved")
        }

        return fileURL
    }

    /// Resolves the configuration file URL, ensuring the file exists on disk.
    /// - Parameter configurationFilePath: Optional configuration file path to use, or nil to search defaults.
    /// - Throws: ValidationError if the file does not exist.
    /// - Returns: The resolved configuration file URL.
    public func resolveConfigurationFileURL(_ configurationFilePath: String?) throws -> URL {
        let configurationFileURL = resolveFilePath(configurationFilePath, variations: Self.defaultConfigurationFilenames)
        guard fileManager.fileExists(at: configurationFileURL) else {
            throw GenericError("No configuration file found")
        }
        return configurationFileURL
    }

    /// Resolves the output directory URL using the provided path, or falls back to the default output directories.
    /// - Parameter outputDirectory: Optional output directory path.
    /// - Returns: The resolved output directory URL.
    public func resolveOutputDirectoryURL(_ outputDirectory: String?) -> URL {
        resolveFilePath(outputDirectory, variations: Self.defaultOutputDirectoryPaths)
    }

    /// Resolves the cache directory URL using the provided path, or falls back to the default cache directories.
    /// - Parameter cacheDirectory: Optional cache directory path.
    /// - Returns: The resolved cache directory URL.
    public func resolveCacheDirectoryURL(_ cacheDirectory: String?) -> URL {
        resolveFilePath(cacheDirectory, variations: Self.defaultCacheDirectoryPaths)
    }

    /// Parses and returns a `BinaryDependenciesConfiguration` from the specified configuration file path.
    /// - Parameters:
    ///   - configurationPath: Optional path to the configuration file.
    ///   - currentToolVersion: Current binary dependency manager version.
    /// - Throws: An error if the file cannot be found, decoded, or the version check fails.
    /// - Returns: The parsed `BinaryDependenciesConfiguration` object.
    public func readConfiguration(
        at configurationPath: String?,
        currentToolVersion: Version
    ) throws -> BinaryDependenciesConfiguration {

        let configurationURL: URL = try resolveConfigurationFileURL(configurationPath)

        // Get the contents of the file
        guard let dependenciesData: Data = fileManager.contents(at: configurationURL) else {
            throw GenericError("Can't get contents of configuration file at \(configurationURL.relativeFilePath)")
        }

        // Decoder selection: Check if this is yaml, and fallback to JSONDecoder.
        let decoder: TopLevelDataDecoder
        if ["yaml", "yml"].contains(configurationURL.pathExtension) {
            decoder = YAMLDecoder()
        } else {
            decoder = JSONDecoder()
        }

        // Parse configuration
        let configuration = try decoder.decode(BinaryDependenciesConfiguration.self, from: dependenciesData)

        // Check minimum required version
        let minimumRequiredVersion = configuration.minimumVersion ?? currentToolVersion
        guard currentToolVersion >= minimumRequiredVersion else {
            throw GenericError("\(configurationPath ?? configurationURL.lastPathComponent) requires version '\(minimumRequiredVersion)', but current version '\(currentToolVersion)' is lower.")
        }

        let dependencies = configuration.dependencies
        let dependenciesInfo = dependencies
            .map { "   \($0.repo)(\($0.tag))" }
            .joined(separator: "\n")
        Logger.log(
            "[Read] Found \(dependencies.count) dependencies:\n\(dependenciesInfo)"
        )

        return configuration
    }
}


/// A type that defines methods for decoding Data.
/// Similar to the TopLevelDecoder with a restricted input to the Data type.
protocol TopLevelDataDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

extension JSONDecoder: TopLevelDataDecoder {}
extension YAMLDecoder: TopLevelDataDecoder {}

#if !canImport(Combine)
extension YAMLDecoder {
    // Yams adds a similar decode function only when Combine framework is available.
    // When Combine is not available (e.g. Linux) YAMLDecoder doesn't conform to the TopLevelDataDecoder.
    // Link: https://github.com/jpsim/Yams/blob/main/Sources/Yams/Decoder.swift#L501-L511

    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        try self.decode(type, from: data, userInfo: [:])
    }
}
#endif
