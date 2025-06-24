/// A protocol for downloading binary dependencies from git repositories.
protocol BinaryDependenciesDownloader {
    /// Downloads the source code as a zip archive from the specified repo and release tag.
    ///
    /// - Parameters:
    ///   - repo: Git repository, e.g. "owner/repo".
    ///   - tag: The release tag to download.
    ///   - outputFilePath: The output file path for the downloaded archive.
    /// - Throws: If the download fails.
    func downloadSourceCode(
        repo: String,
        tag: String,
        outputFilePath: String
    ) throws

    /// Downloads a specific release asset from git repo matching the provided pattern.
    ///
    /// - Parameters:
    ///   - repo: Git repository, e.g. "owner/repo".
    ///   - tag: The release tag to download.
    ///   - pattern: Optional asset name pattern to select the correct file.
    ///   - outputFilePath: Where to save the downloaded asset.
    /// - Throws: If the download fails.
    func downloadReleaseAsset(
        repo: String,
        tag: String,
        pattern: String?,
        outputFilePath: String
    ) throws
}

extension CLI.GitHub: BinaryDependenciesDownloader {}
