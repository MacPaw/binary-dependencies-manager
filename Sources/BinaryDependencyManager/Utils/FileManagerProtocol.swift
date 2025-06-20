import Foundation

protocol FileManagerProtocol {
    /// Returns a Boolean value that indicates whether a file or directory exists at a specified path.
    ///
    /// - Parameter path: The path of the file or directory. If path begins with a tilde (~), it must first be expanded with expandingTildeInPath; otherwise, this method returns false.
    ///
    /// - Returns: true if a file at the specified path exists, or false if the file does not exist or its existence could not be determined.
    func fileExists(atPath path: String) -> Bool

    /// Returns the contents of the file at the specified path.
    /// - Parameters:
    ///   - path: The path of the file whose contents you want.
    /// - Returns: An `Data` object with the contents of the file. If path specifies a directory, or if some other error occurs, this method returns nil.
    func contents(atPath path: String) -> Data?
}

extension FileManager: FileManagerProtocol {}
