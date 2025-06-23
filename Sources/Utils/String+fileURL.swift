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
}
