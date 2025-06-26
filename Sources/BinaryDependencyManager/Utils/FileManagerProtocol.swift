import Foundation

public protocol FileManagerProtocol {
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

    /// The temporary directory for the current user.
    var temporaryDirectory: URL { get }

    /// Removes the file or directory at the specified path.
    /// - Parameters:
    ///   - url: A file URL specifying the file or directory to remove. If the URL specifies a directory, the contents of that directory are recursively removed.
    func removeItem(at url: URL) throws

    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]?) throws

    func contentsOfDirectory(atPath path: String) throws -> [String]

    func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey : Any]?) -> Bool

    func copyItem(at srcURL: URL, to dstURL: URL) throws
}

extension FileManagerProtocol {
    public func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws {
        try createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: .none)
    }

    public func fileExists(at url: URL) -> Bool {
        fileExists(atPath: url.filePath)
    }

    public func contents(at url: URL) -> Data? {
        contents(atPath: url.filePath)
    }

    public func contentsOfDirectory(at url: URL) throws -> [String] {
        try contentsOfDirectory(atPath: url.filePath)
    }

    func createFile(at url: URL, contents data: Data?) -> Bool {
        createFile(atPath: url.filePath, contents: data, attributes: .none)
    }
}

extension FileManager: FileManagerProtocol {}
