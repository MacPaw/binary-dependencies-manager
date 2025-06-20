@testable import BinaryDependencyManager
import Foundation

class FileManagerProtocolMock: FileManagerProtocol {
    var files: Set<String> = []
    func fileExists(atPath path: String) -> Bool {
        files.contains(path)
    }

    var contents: [String: Data] = [:]
    func contents(atPath path: String) -> Data? {
        contents[path]
    }
}
