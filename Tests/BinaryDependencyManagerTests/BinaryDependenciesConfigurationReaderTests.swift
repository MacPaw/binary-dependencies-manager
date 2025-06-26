@testable import BinaryDependencyManager
import XCTest
import Testing
import Yams
import Foundation
import Utils

final class BinaryDependenciesConfigurationReaderTests: XCTestCase {
    private func makeReader(withFiles files: [String]) -> BinaryDependenciesConfigurationReader {
        let mockFileManager = FileManagerProtocolMock()
        mockFileManager.existingFiles = Set(files)
        return BinaryDependenciesConfigurationReader(fileManager: mockFileManager)
    }

    func test_resolveConfigurationFileURL_withExplicitPath() throws {
        let sut = makeReader(withFiles: ["/the/path/.binary-dependencies.yaml"])
        let url = try sut.resolveConfigurationFileURL("/the/path/.binary-dependencies.yaml")
        XCTAssertEqual(url.path, "/the/path/.binary-dependencies.yaml")
        XCTAssertEqual(url.filePath, "/the/path/.binary-dependencies.yaml")
    }

    func test_resolveConfigurationFileURL_fallbackToDefault() throws {
        let sut = makeReader(withFiles: [".binary-dependencies.yaml".asFileURL.filePath])
        let url = try sut.resolveConfigurationFileURL(nil)
        XCTAssertEqual(url.lastPathComponent, ".binary-dependencies.yaml")
    }

    func test_resolveConfigurationFileURL_fileDoesNotExist_throws() {
        let sut = makeReader(withFiles: [])
        XCTAssertThrowsError(try sut.resolveConfigurationFileURL(nil))
    }

    func test_resolveOutputDirectoryURL_explicit() {
        let sut = makeReader(withFiles: [])
        let url = sut.resolveOutputDirectoryURL("Explicit/Output")
        XCTAssertEqual(url, "Explicit/Output".asFileURL)
    }

    func test_resolveCacheDirectoryURL_explicit() {
        let sut = makeReader(withFiles: [])
        let url = sut.resolveCacheDirectoryURL("Explicit/Cache")
        XCTAssertEqual(url, "Explicit/Cache".asFileURL)
    }

    func test_readConfiguration_parsesYAML() throws {
        // GIVEN
        let yamlString = """
        minimumVersion: 0.0.1
        outputDirectory: output/directory
        cacheDirectory: cache/directory
        dependencies:
          - repo: test/repo
            tag: "0.0.1"
            pattern: pattern1
            checksum: "check1"
        """
        let filePath = ".binary-dependencies.yaml".asFileURL.filePath
        let data = Data(yamlString.utf8)
        let mockFileManager = FileManagerProtocolMock()
        mockFileManager.existingFiles = [filePath]
        mockFileManager.contents = [filePath: data]

        let sut = BinaryDependenciesConfigurationReader(fileManager: mockFileManager)

        // WHEN
        let config = try sut.readConfiguration(at: .none)

        // THEN
        let expected = BinaryDependenciesConfiguration(
            minimumVersion: Version(string: "0.0.1"),
            outputDirectory: "output/directory",
            cacheDirectory: "cache/directory",
            dependencies: [
                Dependency(
                    repo: "test/repo",
                    tag: "0.0.1",
                    assets: [Dependency.Asset(checksum: "check1", pattern: "pattern1")]
                )
            ]
        )
        XCTAssertEqual(config, expected)
    }
}

