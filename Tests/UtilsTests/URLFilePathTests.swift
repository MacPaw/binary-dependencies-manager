import Foundation
import Testing

@Suite("Tests for URL+filePath extensions")
struct URLFilePathTests {
    @Test("appending(pathComponents:isDirectory:) appends multiple path components correctly directories")
    func test_appendingPathComponents_dir() {
        // GIVEN
        let base = URL(fileURLWithPath: "/tmp")

        // WHEN
        let dirURL = base.appending(pathComponents: "foo", "bar", isDirectory: true)

        // THEN
        #expect(dirURL.path.hasSuffix("/foo/bar"), "Directory URL should end with /foo/bar")
        #expect(dirURL.hasDirectoryPath, "Should flag as directory")
    }

    @Test("appending(pathComponents:isDirectory:) appends multiple path components correctly for files")
    func test_appendingPathComponents_file() {
        // GIVEN
        let base = URL(fileURLWithPath: "/tmp")

        // WHEN
        let fileURL = base.appending(pathComponents: "foo", "bar.txt", isDirectory: false)

        // THEN
        #expect(fileURL.path.hasSuffix("/foo/bar.txt"), "File URL should end with /foo/bar.txt")
        #expect(!fileURL.hasDirectoryPath, "Should not flag as directory")
    }

    @Test("appending(pathComponents:isDirectory:) appends multiple path components correctly directories")
    func test_appendingPathComponents_empty_components() {
        // GIVEN
        let base = URL(fileURLWithPath: "/tmp")

        // WHEN
        let fileURL = base
            .appending(pathComponents: "", "", "foo", "", "", "bar", "", "", isDirectory: true)
            .appending(pathComponents: "", isDirectory: true)
            .appending(pathComponents: "some file.txt", isDirectory: false)

        // THEN
        #expect(fileURL.filePath.hasSuffix("/foo/bar/some file.txt"), "File URL should end with /foo/bar/some file.txt")
    }

    @Test("filePath returns correct path with or without percent encoding on different platforms")
    func test_filePath() throws {
        let original = "/tmp/some file.txt"
        let encoded = original.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let url = try #require(URL(string: "file://" + encoded))
        // filePath should match the normal path
        #expect(url.filePath.hasSuffix("some file.txt"), "filePath should remove percent encoding if present")
    }

    @Test("relativeFilePath returns './' prefixed path when under current directory")
    func test_relativeFilePath() {
        let cwd = FileManager.default.currentDirectoryPath
        let fileName = "test.txt"
        let url = URL(fileURLWithPath: cwd).appending(pathComponents: fileName, isDirectory: false)
        #expect(url.relativeFilePath.hasPrefix("./"), "Should prefix with ./")
        #expect(url.relativeFilePath.hasSuffix(fileName), "Should end with the file name")
    }

    @Test("relativeFilePath returns absolute path for files outside current directory")
    func test_relativeFilePath_outsideCWD() {
        let url = URL(fileURLWithPath: "/tmp/outside.txt")
        #expect(url.relativeFilePath == url.filePath, "Should match filePath for files not under CWD")
    }
}
