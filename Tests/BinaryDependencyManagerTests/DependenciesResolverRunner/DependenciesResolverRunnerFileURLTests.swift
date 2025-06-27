import Testing
import Foundation
@testable import BinaryDependencyManager

@Suite("DependenciesResolverRunner file URL logic")
struct DependenciesResolverRunnerFileURLTests {

    let dependency = Dependency(repo: "owner/repo", tag: "1.0.0", assets: [
        Dependency.Asset(checksum: "abc123", pattern: "lib.zip", contents: "Frameworks/Lib.xcframework", outputDirectory: "Lib")
    ])

    let asset = Dependency.Asset(checksum: "abc123", pattern: "lib.zip", contents: "Frameworks/Lib.xcframework", outputDirectory: "Lib")
    let outputRoot = "output".asFileURL
    let cacheRoot = "cache".asFileURL

    @Test
    func test_downloadsDirectoryURL_relative() async throws {
        let runner = DependenciesResolverRunner.mock(
            dependencies: [dependency],
            outputDirectoryURL: outputRoot,
            cacheDirectoryURL: cacheRoot
        )
        let downloadsDir = runner.downloadsDirectoryURL
        #expect(downloadsDir.path(percentEncoded: false).hasSuffix("/cache/.downloads/"))
        #expect(downloadsDir.path(percentEncoded: false).hasPrefix(FileManager.default.currentDirectoryPath))
        #expect(
            downloadsDir == FileManager.default.currentDirectoryPath.asFileURL
                .appending(components: "cache", ".downloads", directoryHint: .isDirectory)
        )
    }

    @Test
    func test_downloadsDirectoryURL_absolute() async throws {
        let runner = DependenciesResolverRunner.mock(
            dependencies: [dependency],
            outputDirectoryURL: outputRoot,
            cacheDirectoryURL: "/cache".asFileURL
        )
        let downloadsDir = runner.downloadsDirectoryURL
        #expect(downloadsDir.path(percentEncoded: false).hasSuffix("/cache/.downloads/"))
        #expect(!downloadsDir.path(percentEncoded: false).hasPrefix(FileManager.default.currentDirectoryPath))
        #expect(downloadsDir == "/cache/.downloads/".asFileURL)
        #expect(downloadsDir.path == "/cache/.downloads")
    }

    @Test
    func test_downloadDirectoryURL_and_downloadPath() async throws {
        let runner = DependenciesResolverRunner.mock(
            dependencies: [dependency],
            outputDirectoryURL: outputRoot,
            cacheDirectoryURL: cacheRoot
        )
        let url = runner.downloadDirectoryURL(for: dependency, asset: asset)
        #expect(url.path(percentEncoded: false).hasSuffix("/cache/.downloads/owner/repo/1.0.0/Lib/"))
        let downloadURL = runner.downloadURL(for: dependency, asset: asset)
        #expect(downloadURL.lastPathComponent == "abc123.zip")
    }

    @Test
    func test_outputDirectoryURL() async throws {
        let runner = DependenciesResolverRunner.mock(
            dependencies: [dependency],
            outputDirectoryURL: outputRoot,
            cacheDirectoryURL: cacheRoot
        )
        let out = runner.outputDirectoryURL(for: dependency, asset: asset)
        #expect(out.path(percentEncoded: false).hasSuffix("/output/owner/repo/Lib/"))
    }

    @Test
    func test_outputDirectoryHashFile() async throws {
        let runner = DependenciesResolverRunner.mock(
            dependencies: [dependency],
            outputDirectoryURL: outputRoot,
            cacheDirectoryURL: cacheRoot
        )
        let hashURL = try runner.outputDirectoryHashFile(for: dependency, asset: asset)
        #expect(hashURL.path(percentEncoded: false).hasSuffix("/output/owner/repo/Lib/.lib_zip_Frameworks_Lib_xcframework.hash"))
    }

    @Test
    func test_createDirectoryIfNeeded_creates_when_missing() async throws {
        let mock = FileManagerProtocolMock()
        let runner = DependenciesResolverRunner.mock(
            dependencies: [dependency],
            outputDirectoryURL: outputRoot,
            cacheDirectoryURL: cacheRoot,
            fileManager: mock
        )
        let newURL = URL(fileURLWithPath: "/made/dir")
        try runner.createDirectoryIfNeeded(at: newURL)
        // Should be recorded in mock
        #expect(mock.createdDirectories.contains(newURL))
    }

    @Test
    func test_createDirectoryIfNeeded_skips_if_exists() async throws {
        let mock = FileManagerProtocolMock()
        let url = URL(fileURLWithPath: "/exists/dir")
        mock.existingFiles.insert(url.path(percentEncoded: false))
        let runner = DependenciesResolverRunner.mock(
            dependencies: [dependency],
            outputDirectoryURL: outputRoot,
            cacheDirectoryURL: cacheRoot,
            fileManager: mock
        )
        try runner.createDirectoryIfNeeded(at: url)
        // Should not record creation
        #expect(!mock.createdDirectories.contains(url))
    }
}
