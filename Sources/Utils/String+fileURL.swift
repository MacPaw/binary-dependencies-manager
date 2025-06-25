import Foundation

extension String {
    /// Absolute file URL with standardized path.
    ///
    /// - Note: Used to avoid deprecation warnings.
    public var asFileURL: URL {
        let url = if #available(macOS 13.0, *) {
            URL(filePath: self)
        } else {
            URL(fileURLWithPath: self)
        }
        return url.standardizedFileURL.absoluteURL
    }

    /// Normalized filename from the string.
    ///
    /// Returns a valid filename by removing any invalid characters and replacing spaces with underscores.
    /// Allowed characters are alphanumeric, underscores, and hyphens.
    public var asFilename: String {
        let invalidCharacters = CharacterSet.alphanumerics.union(.whitespaces).inverted
        let sanitized = components(separatedBy: invalidCharacters).joined(separator: "_")
        return sanitized.replacingOccurrences(of: " ", with: "_")
    }
}
