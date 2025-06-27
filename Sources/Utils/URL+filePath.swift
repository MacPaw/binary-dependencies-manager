import Foundation

extension URL {
    /// Returns a URL constructed by appending the given variadic list of path components to self.
    ///
    /// - Note: Used to avoid deprecation warning for newer macOS.
    ///
    /// - Parameters:
    ///   - pathComponents: The list of the path components to add.
    ///   - isDirectory: A `Bool` flag to whether this URL will point to a directory.
    ///
    /// - Returns: The URL with the appended path components.
    public func appending(pathComponents: String..., isDirectory: Bool) -> URL {
        var result = self

        // Remove empty path components to avoid double slashes.
        let pathComponents = pathComponents.filter { !$0.isEmpty }

        if #available(macOS 13.0, *) {
            for path in pathComponents[0..<max(pathComponents.count - 1, 0)] {
                result.append(path: path, directoryHint: .isDirectory)
            }
            if let lastComponent = pathComponents.last {
                result.append(path: lastComponent, directoryHint: isDirectory ? .isDirectory : .inferFromPath)
            }
        }
        else {
            result.appendPathComponent(pathComponents.joined(separator: "/"), isDirectory: isDirectory)
        }
        return result
    }

    /// Returns the path component of the URL, removing any percent-encoding.
    ///
    /// - Note: Used to avoid deprecation warning for newer macOS.
    public var filePath: String {
        if #available(macOS 13.0, *) {
            path(percentEncoded: false)
        }
        else {
            path
        }
    }

    /// Returns a relative path to the file from the current working directory.
    ///
    /// - Note: Used in the logs to simplify output.
    public var relativeFilePath: String {
        guard filePath.hasPrefix(FileManager.default.currentDirectoryPath + "/") else {
            return filePath
        }
        // Drop leading occurrence of the current directory path.
        return "./" + String(filePath.dropFirst(FileManager.default.currentDirectoryPath.count + 1))
    }
}
