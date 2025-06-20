import Foundation

extension CLI {
    /// Helper for interacting with the GitHub CLI (`gh`)
    struct GitHub {
        let cliURL: URL
    }
}

extension CLI.GitHub {
    /// Initializes a `CLI.GitHub` by resolving the path to the `gh` command-line tool.
    ///
    /// - Throws: An error if the `gh` CLI cannot be found in PATH.
    init() throws {
        self.init(cliURL: try CLI.which(cliToolName: "gh"))
    }
}

extension CLI.GitHub {
    /// Runs the GitHub CLI (`gh`) command with the given arguments.
    ///
    /// - Parameters:
    ///   - arguments: Arguments to pass to `gh`.
    ///   - currentDirectoryURL: Optional working directory for the command.
    /// - Returns: The standard output as a string.
    /// - Throws: An error if the process fails or cannot be run.
    @discardableResult
    func run(arguments: [String], currentDirectoryURL: URL? = .none) throws -> String {
        try CLI.run(
            executableURL: cliURL,
            arguments: arguments,
            currentDirectoryURL: currentDirectoryURL
        )
    }

    /// Downloads the source code as a zip archive from the specified repo and release tag using `gh`.
    ///
    /// - Parameters:
    ///   - repo: GitHub repository, e.g. "owner/repo".
    ///   - tag: The release tag to download.
    ///   - outputFilePath: The output file path for the downloaded archive.
    /// - Throws: If the download fails.
    func downloadSourceCode(
        repo: String,
        tag: String,
        outputFilePath: String
    ) throws {
        let arguments: [String] = [
            ["release"],
            ["download"],
            ["\(tag)"],
            ["--archive=zip"],
            ["--repo", "\(repo)"],
            ["--output", "\(outputFilePath)"]
        ].flatMap { $0 }

        Logger.log("[Download] ⬇️ \(repo) source code with tag \(tag) to \(outputFilePath)")

        try run(
            arguments: arguments,
            currentDirectoryURL: outputFilePath.asFileURL.deletingLastPathComponent()
        )
    }

    /// Downloads a specific release asset from GitHub matching the provided pattern using `gh`.
    ///
    /// - Parameters:
    ///   - repo: GitHub repository, e.g. "owner/repo".
    ///   - tag: The release tag to download.
    ///   - pattern: Optional asset name pattern to select the correct file.
    ///   - outputFilePath: Where to save the downloaded asset.
    /// - Throws: If the download fails.
    func downloadReleaseAsset(
        repo: String,
        tag: String,
        pattern: String?,
        outputFilePath: String
    ) throws {
        let arguments: [String] = [
            ["release"],
            ["download"],
            ["\(tag)"],
            pattern.map { ["--pattern", "\($0)"] } ?? [],
            ["--repo", "\(repo)"],
            ["--output", "\(outputFilePath)"]
        ].flatMap { $0 }

        Logger.log("[Download] ⬇️ \(repo) release asset with tag \(tag) to \(outputFilePath)")

        try run(
            arguments: arguments,
            currentDirectoryURL: outputFilePath.asFileURL.deletingLastPathComponent()
        )
    }
}
