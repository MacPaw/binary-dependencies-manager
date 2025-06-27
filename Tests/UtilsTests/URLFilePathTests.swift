import Foundation
import Testing

@Suite("Tests for URL+filePath extensions")
struct URLFilePathTests {
    @Test("relativeFilePath returns './' prefixed path when under current directory")
    func test_relativeFilePath() {
        let cwd = FileManager.default.currentDirectoryPath
        let fileName = "test.txt"
        let url = URL(fileURLWithPath: cwd).appending(path: fileName, directoryHint: .notDirectory)
        #expect(url.relativeFilePath.hasPrefix("./"), "Should prefix with ./")
        #expect(url.relativeFilePath.hasSuffix(fileName), "Should end with the file name")
    }

    @Test("relativeFilePath returns absolute path for files outside current directory")
    func test_relativeFilePath_outsideCWD() {
        let url = URL(fileURLWithPath: "/tmp/outside.txt")
        #expect(url.relativeFilePath == url.path(percentEncoded: false), "Should match filePath for files not under CWD")
    }
}
