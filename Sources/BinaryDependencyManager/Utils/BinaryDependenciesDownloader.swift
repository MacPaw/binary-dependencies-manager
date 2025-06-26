import Utils

/// A protocol for downloading binary dependencies from git repositories.
public protocol BinaryDependenciesDownloader {
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
