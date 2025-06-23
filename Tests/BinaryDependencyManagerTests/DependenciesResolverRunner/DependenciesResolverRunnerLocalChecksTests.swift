import Testing
import Foundation
@testable import BinaryDependencyManager
import Utils
import Crypto

@Suite("DependenciesResolverRunner Core Local Checks Methods")
struct DependenciesResolverRunnerLocalChecksTests {
    let sampleDependency: Dependency = Dependency(
        repo: "org/repo",
        tag: "1.0.0",
        assets: [
            Dependency.Asset(
                checksum: "abc123",
                pattern: "asset.zip",
                contents: nil,
                outputDirectory: nil
            )
        ]
    )

    let tempDir: URL = {
        FileManager.default.temporaryDirectory
            .appending(pathComponents: "binary-dependency-manager-tests", UUID().uuidString, isDirectory: true)
    }()

    let checksumCalculatorMock: ChecksumCalculatorProtocolMock = .init()

    func makeRunner(fileManager: FileManagerProtocolMock, dependencies: [Dependency]? = .none) throws -> DependenciesResolverRunner {
        DependenciesResolverRunner.mock(
            dependencies: dependencies ?? [sampleDependency],
            outputDirectoryURL: tempDir.appending(pathComponents: "output", isDirectory: true),
            cacheDirectoryURL: tempDir.appending(pathComponents: "cache", isDirectory: true),
            fileManager: fileManager,
            uuidString: "mock-uuid",
            checksumCalculator: checksumCalculatorMock
        )
    }

    @Test("shouldResolve returns true when hash file is missing")
    func shouldResolve_missingHashFile() async throws {
        // GIVEN
        let fileManager = FileManagerProtocolMock(tempDir: tempDir)
        let runner = try makeRunner(fileManager: fileManager)
        let sampleAsset: Dependency.Asset = sampleDependency.assets[0]

        // WHEN
        let shouldResolve = try runner.shouldResolve(sampleDependency, asset: sampleAsset)

        // THEN
        #expect(shouldResolve == true)
    }

    @Test("shouldResolve returns false when hash matches checksum")
    func shouldResolve_matchingHash() async throws {
        // GIVEN
        let fileManager = FileManagerProtocolMock(tempDir: tempDir)
        let runner = try makeRunner(fileManager: fileManager)
        let sampleAsset: Dependency.Asset = sampleDependency.assets[0]
        let hashURL = try runner.outputDirectoryHashFile(for: sampleDependency, asset: sampleAsset)
        fileManager.contents[hashURL.filePath] = Data("abc123".utf8)

        // WHEN
        let shouldResolve = try runner.shouldResolve(sampleDependency, asset: sampleAsset)

        // THEN
        #expect(shouldResolve == false)
    }

    @Test("shouldResolve returns true when hash file is present but mismatched")
    func shouldResolve_mismatchedHash() async throws {
        // GIVEN
        let fileManager = FileManagerProtocolMock(tempDir: tempDir)
        let runner = try makeRunner(fileManager: fileManager)
        let sampleAsset: Dependency.Asset = sampleDependency.assets[0]
        let hashURL = try runner.outputDirectoryHashFile(for: sampleDependency, asset: sampleAsset)
        fileManager.contents[hashURL.filePath] = Data("different".utf8)

        // WHEN
        let shouldResolve = try runner.shouldResolve(sampleDependency, asset: sampleAsset)

        // THEN
        #expect(shouldResolve == true)
    }

    @Test("markAsResolved creates hash file with correct content")
    func markAsResolved_createsHashFile() async throws {
        // GIVEN
        let fileManager = FileManagerProtocolMock(tempDir: tempDir)
        let runner = try makeRunner(fileManager: fileManager)
        let sampleAsset: Dependency.Asset = sampleDependency.assets[0]

        // WHEN
        try runner.markAsResolved(sampleDependency, asset: sampleAsset)

        let hashURL = try runner.outputDirectoryHashFile(for: sampleDependency, asset: sampleAsset)

        // THEN
        // check if the hash file was created
        let hashData = fileManager.contents[hashURL.filePath]
        #expect(hashData == Data("abc123".utf8))
    }

    @Test("isFileDownloaded returns false if file not present")
    func isFileDownloaded_fileMissing() async throws {
        // GIVEN
        let fileManager = FileManagerProtocolMock(tempDir: tempDir)
        let runner = try makeRunner(fileManager: fileManager)
        let sampleAsset: Dependency.Asset = sampleDependency.assets[0]

        // WHEN
        let result = try runner.isFileDownloaded(for: sampleDependency, asset: sampleAsset)

        // THEN
        #expect(result == false)
    }

    @Test("isFileDownloaded returns true if present and checksum matches")
    func isFileDownloaded_success() async throws {
        // GIVEN
        let fileManager = FileManagerProtocolMock(tempDir: tempDir)
        let runner = try makeRunner(fileManager: fileManager)
        let sampleAsset: Dependency.Asset = sampleDependency.assets[0]
        let zipFileURL = runner.downloadURL(for: sampleDependency, asset: sampleAsset)
        // .zip file exists
        fileManager.existingFiles.insert(zipFileURL.filePath)
        // checksum is correct
        checksumCalculatorMock.checksums[zipFileURL] = sampleAsset.checksum

        // WHEN
        let result = try runner.isFileDownloaded(for: sampleDependency, asset: sampleAsset)

        // THEN
        #expect(result == true)
    }
}
