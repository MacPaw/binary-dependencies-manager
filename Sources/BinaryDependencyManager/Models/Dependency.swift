// Dependency representation
struct Dependency: Codable {

    /// Repository in format "owner/repo" i.e. "MyRepo/MyAwesomeLibrary"
    let repo: String

    /// Tag in format "0.0.47", Basically a release
    let tag: String

    /// Sha256 checksum of the zip archive
    let checksum: String

    /// Optional. If provided, the contents of `contents` director in archive will be copied to output directory
    let contents: String?

    /// Optional. This can be used to select specific artifact, if multiple artifacts are added to the the release
    let pattern: String?

    /// Optional. Іf defined, the subdirectory with a given name will be created inside download directory.
    /// Use when you want to download multiple artifacts from the same repository.
    let output: String?
}
