/// Dependency representation
public struct Dependency: Equatable {
    /// Repository in format "owner/repo" i.e. "MacPaw/CMMX-Panther-Engine"
    public let repo: String

    /// Tag in format "0.0.47", Basically a release
    public let tag: String

    /// List of assets to download.
    public let assets: [Asset]
}

// MARK: Decodable

extension Dependency: Decodable {
    private enum CodingKeys: String, CodingKey {
        case repo
        case tag
        case assets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.repo = try container.decode(String.self, forKey: .repo)
        self.tag = try container.decode(String.self, forKey: .tag)
        var assets = try container.decodeIfPresent([Asset].self, forKey: .assets) ?? []

        // If there are no nested assets, try to decode a single asset params from the dependency level.
        if assets.isEmpty {
            assets = try [Asset(from: decoder)]
        }

        self.assets = assets
    }
}

// MARK: Encodable

extension Dependency: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(repo, forKey: .repo)
        try container.encode(tag, forKey: .tag)
        try container.encode(assets, forKey: .assets)
    }
}

// MARK: - Dependency.Asset

extension Dependency {
    public struct Asset: Equatable, Sendable {
        /// SHA-256 checksum of the zip archive.
        public let checksum: String
        /// Regex pattern to a specific artifact, if multiple artifacts are added to the the release assets.
        public let pattern: String?
        /// If provided, the contents of `contents` directory in the Source Code archive will be copied to output directory.
        /// - Warning: if provided it takes precedence over the `pattern`.
        public let contents: String?
        /// Custom output directory for the asset.
        public let outputDirectory: String?

        init (
            checksum: String,
            pattern: String? = nil,
            contents: String? = nil,
            outputDirectory: String? = nil
        ) {
            self.checksum = checksum
            self.pattern = pattern
            self.contents = contents
            self.outputDirectory = outputDirectory
        }
    }
}

// MARK: Decodable

extension Dependency.Asset: Decodable {
    private enum CodingKeys: String, CodingKey {
        case checksum
        case pattern
        case contents
        case outputDirectory = "output"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.checksum = try container.decode(String.self, forKey: .checksum)
        self.pattern = try container.decodeIfPresent(String.self, forKey: .pattern)
        self.contents = try container.decodeIfPresent(String.self, forKey: .contents)
        self.outputDirectory = try container.decodeIfPresent(String.self, forKey: .outputDirectory)
    }
}

// MARK: Encodable

extension Dependency.Asset: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(checksum, forKey: .checksum)
        try container.encodeIfPresent(pattern, forKey: .pattern)
        try container.encodeIfPresent(contents, forKey: .contents)
        try container.encodeIfPresent(outputDirectory, forKey: .outputDirectory)
    }
}
