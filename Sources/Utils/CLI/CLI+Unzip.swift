import Foundation

extension CLI {
    /// Helper for interacting with the unzip CLI (`unzip`)
    public struct Unzip {
        let cliURL: URL
    }
}

extension CLI.Unzip {
    /// Initializes a `CLI.Unzip` by resolving the path to the `unzip` command-line tool.
    ///
    /// - Throws: An error if the `unzip` CLI cannot be found in PATH.
    public init() throws {
        self.init(cliURL: try CLI.which(cliToolName: "unzip"))
    }
}

extension CLI.Unzip {
    /// Runs the `unzip` CLI command with the given arguments.
    ///
    /// - Parameters:
    ///   - arguments: Arguments to pass to `unzip`.
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

    /// Extracts contents of the `archiveFilePath` zip archive to the given `outputFilePath`.
    ///
    /// - Parameters:
    ///   - archiveFilePath: A path to the archive file to inflate.
    ///   - outputFilePath: Where to extract the contents of the given archive.
    /// - Throws: If the inflating process fails.
    public func unzip(
        archivePath: String,
        outputFilePath: String
    ) throws {
        let arguments: [String] = [
            // Quiet
            ["-q"],
            // Source
            [archivePath],
            // Destination
            ["-d", outputFilePath]
        ].flatMap { $0 }

        Logger.log("[Unzip] ⬇️ \(archivePath) to \(outputFilePath)")

        try run(
            arguments: arguments,
            currentDirectoryURL: outputFilePath.asFileURL.deletingLastPathComponent()
        )
    }
}
