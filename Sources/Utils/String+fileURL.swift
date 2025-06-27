import Foundation

extension String {
    /// Absolute file URL with standardized path.
    ///
    /// - Note: Used to avoid deprecation warnings.
    public var asFileURL: URL {
        URL(filePath: self).standardizedFileURL.absoluteURL
    }
}
