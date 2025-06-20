import Foundation

/// Binary dependencies configuration.
struct BinaryDependenciesConfiguration: Equatable {
    /// Minimum version of the `binary-dependencies-manager` CLI.
    var minimumVersion: Version?
    /// Path to the output directory, where downloaded dependencies will be placed.
    var outputDirectory: String?
    /// Path to the cache directory.
    var cacheDirectory: String?
    /// Dependencies list.
    var dependencies: [Dependency]
}

extension BinaryDependenciesConfiguration: Codable {

    private enum CodingKeys: String, CodingKey {
        case minimumVersion
        case outputDirectory
        case cacheDirectory
        case dependencies
    }

    init(from decoder: any Decoder) throws {
        do {
            // Decode full schema
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.dependencies = try container.decode([Dependency].self, forKey: .dependencies)

            let minimumVersion = try container.decodeIfPresent(String.self, forKey: .minimumVersion)
            self.minimumVersion = minimumVersion.flatMap(Version.init(_:))

            self.outputDirectory = try container.decodeIfPresent(String.self, forKey: .outputDirectory)
            self.cacheDirectory = try container.decodeIfPresent(String.self, forKey: .cacheDirectory)

        } catch {
            // Try to decode array
            var container = try decoder.unkeyedContainer()
            var dependencies: [Dependency] = []
            while !container.isAtEnd {
                try dependencies.append(container.decode(Dependency.self))
            }
            self.dependencies = dependencies
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.minimumVersion?.description, forKey: .minimumVersion)
        try container.encodeIfPresent(self.outputDirectory, forKey: .outputDirectory)
        try container.encodeIfPresent(self.cacheDirectory, forKey: .cacheDirectory)
        try container.encode(self.dependencies, forKey: .dependencies)
    }
}
