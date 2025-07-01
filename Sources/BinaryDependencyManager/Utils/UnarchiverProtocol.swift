import Foundation
import Utils

public protocol UnarchiverProtocol {
    /// Extracts contents of the `archiveFilePath` zip archive to the given `outputFilePath`.
    ///
    /// - Parameters:
    ///   - archiveFilePath: A path to the archive file to inflate.
    ///   - outputFilePath: Where to extract the contents of the given archive.
    /// - Throws: If the inflating process fails.
    func unzip(
        archivePath: String,
        outputFilePath: String
    ) throws
}

extension CLI.Unzip: UnarchiverProtocol {}
