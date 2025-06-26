@testable import BinaryDependencyManager
import Foundation

class FileManagerProtocolMock: FileManagerProtocol {
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]?) throws {
        createdDirectories.append(url)
    }

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        []
    }

    var existingFiles: Set<String> = []
    func fileExists(atPath path: String) -> Bool {
        existingFiles.contains(path)
    }

    var contents: [String: Data] = [:]
    func contents(atPath path: String) -> Data? {
        contents[path]
    }

    var createdDirectories: [URL] = []
    var contentsMap: [URL: Data] = [:]
    var removedItems: [URL] = []
    var tempDir: URL

    init(tempDir: URL = URL(fileURLWithPath: "/tmp/mock")) {
        self.tempDir = tempDir
    }

    var temporaryDirectory: URL { tempDir }
    func contents(at url: URL) -> Data? { contentsMap[url] }
    func removeItem(at url: URL) throws { removedItems.append(url) }

    var createdFiles: [String] = []
    func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey : Any]?) -> Bool {
        guard !createdFiles.contains(path) else { return false }

        createdFiles.append(path)
        contents[path] = data

        return true
    }
}
