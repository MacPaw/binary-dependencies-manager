import Testing
import Foundation
@testable import BinaryDependencyManager
import Utils

extension DependenciesResolverRunnerTests {

    @Test("downloadsDirectoryURL returns correct path")
    func test_downloadsDirectoryURL_relative() async throws {
        // GIVEN
        let relativePath = "relative/cache"
        let runner = makeRunner(cachePath: relativePath)

        // WHEN
        let downloadsDir = runner.downloadsDirectoryURL

        // THEN
        #expect(downloadsDir.path(percentEncoded: false).hasPrefix(FileManager.default.currentDirectoryPath))
        #expect(downloadsDir.path(percentEncoded: false).hasSuffix("/\(relativePath)/.downloads/"))
        #expect(
            downloadsDir == FileManager.default.currentDirectoryPath.asFileURL
                .appending(path: "relative/cache/.downloads", directoryHint: .isDirectory)
        )
    }

    @Test(
        "outputDirectoryURL returns correct relative path if non-root path provided",
        arguments:[
            Dependency.Asset.init(checksum: "", outputDirectory: .none), // w/o custom output dir
            Dependency.Asset.init(checksum: "", outputDirectory: "some"), // with custom output dir
        ]
    )
    func test_outputDirectoryURL_relative(sampleAsset: Dependency.Asset) async throws {
        // GIVEN
        let relativePath = "relative/output"
        let runner = makeRunner(sampleAsset: sampleAsset, outputPath: relativePath)

        // WHEN
        let outputDir = runner.outputDirectoryURL(for: sampleDependency, asset: sampleAsset)

        // THEN
        // Partial compare
        #expect(outputDir.path(percentEncoded: false).hasPrefix(FileManager.default.currentDirectoryPath))
        #expect(outputDir.path(percentEncoded: false).contains("/\(relativePath)/"))
        #expect(outputDir.path(percentEncoded: false).contains("/\(sampleDependency.repo)/"))
        if let outputDirectory = sampleAsset.outputDirectory {
            #expect(outputDir.path(percentEncoded: false).hasSuffix("/\(outputDirectory)/"))
        }

        // Full compare
        #expect(
            outputDir == FileManager.default.currentDirectoryPath.asFileURL
                .appending(
                    components: "relative/output/org/repo", sampleAsset.outputDirectory ?? "",
                    directoryHint: .isDirectory
                ).standardizedFileURL
        )
    }

    @Test
    func test_downloadURL() async throws {
        // GIVEN
        let runner = makeRunner()

        // WHEN
        let downloadURL = runner.downloadURL(for: sampleDependency, asset: sampleAsset)

        // THEN
        #expect(
            downloadURL == tempDir.appending(
                path: "cache/.downloads/org/repo/1.0.0/abc123.zip",
                directoryHint: .notDirectory
            ).standardizedFileURL
        )
    }

    @Test
    func test_outputDirectoryHashFile() async throws {
        // GIVEN
        let runner = makeRunner()

        // WHEN
        let hashURL = try runner.outputDirectoryHashFile(for: sampleDependency, asset: sampleAsset)

        // THEN
        #expect(
            hashURL == tempDir.appending(
                path: "output/org/repo/.asset_zip.hash",
                directoryHint: .notDirectory
            )
        )
    }

    @Test
    func test_createDirectoryIfNeeded_creates_when_missing() async throws {
        // GIVEN
        let runner = makeRunner()
        let newURL = URL(fileURLWithPath: "/new/dir")

        // WHEN
        try runner.createDirectoryIfNeeded(at: newURL)

        // THEN
        // Should be recorded in mock
        #expect(fileManager.createdDirectories.contains(newURL))
    }

    @Test
    func test_createDirectoryIfNeeded_skips_if_exists() async throws {
        // GIVEN
        let runner = makeRunner()

        let existingURL = URL(fileURLWithPath: "/new/dir")
        fileManager.existingFiles.insert(existingURL.path(percentEncoded: false))

        // WHEN
        try runner.createDirectoryIfNeeded(at: existingURL)

        // THEN
        // Should not record creation
        #expect(!fileManager.createdDirectories.contains(existingURL))
    }
}
