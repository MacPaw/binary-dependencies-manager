import Foundation

extension URL {
    /// Returns a relative path to the file from the current working directory.
    ///
    /// - Note: Used in the logs to simplify output.
    public var relativeFilePath: String {
        let filePath = path(percentEncoded: false)
        guard filePath.hasPrefix(FileManager.default.currentDirectoryPath + "/") else {
            return filePath
        }
        // Drop leading occurrence of the current directory path.
        return "./" + String(filePath.dropFirst(FileManager.default.currentDirectoryPath.count + 1))
    }
}
