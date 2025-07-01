@testable import BinaryDependencyManager
import Foundation

class FileManagerProtocolMock: FileManagerProtocol {
    var copiedFiles: [URL: URL] = [:]
    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        copiedFiles[srcURL] = dstURL
        existingFiles.insert(dstURL.path(percentEncoded: false))
        contentsMap[dstURL] = contentsMap[srcURL]
    }

    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]?) throws {
        createdDirectories.append(url)
    }

    var directoryContents: [String: [String]] = [:]
    func contentsOfDirectory(atPath path: String) throws -> [String] {
        directoryContents[path] ?? []
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
    func removeItem(at url: URL) throws {
        removedItems.append(url)
        existingFiles.remove(url.path(percentEncoded: false))
        contentsMap[url] = .none
    }

    var createdFiles: [String] = []
    func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey : Any]?) -> Bool {
        guard !createdFiles.contains(path) else { return false }

        createdFiles.append(path)
        contents[path] = data

        return true
    }
}
