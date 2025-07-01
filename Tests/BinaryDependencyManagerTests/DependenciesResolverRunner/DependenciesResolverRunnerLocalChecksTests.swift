import Testing
import Foundation
@testable import BinaryDependencyManager
import Utils
import Crypto

extension DependenciesResolverRunnerTests {
   @Test("shouldResolve returns true when hash file is missing")
    func shouldResolve_missingHashFile() async throws {
        // GIVEN
        let runner = makeRunner()

        // WHEN
        let shouldResolve = try runner.shouldResolve(sampleDependency, asset: sampleAsset)

        // THEN
        #expect(shouldResolve == true)
    }

    @Test("shouldResolve returns false when hash matches checksum")
    func shouldResolve_matchingHash() async throws {
        // GIVEN
        let runner = makeRunner()

        // Mock valid hash file
        let hashURL = try runner.outputDirectoryHashFile(for: sampleDependency, asset: sampleAsset)
        fileManager.contents[hashURL.path(percentEncoded: false)] = Data("abc123".utf8)

        // WHEN
        let shouldResolve = try runner.shouldResolve(sampleDependency, asset: sampleAsset)

        // THEN
        #expect(shouldResolve == false)
    }

    @Test("shouldResolve returns true when hash file is present but mismatched")
    func shouldResolve_mismatchedHash() async throws {
        // GIVEN
        let runner = makeRunner()

        // Mock invalid hash file
        let hashURL = try runner.outputDirectoryHashFile(for: sampleDependency, asset: sampleAsset)
        fileManager.contents[hashURL.path(percentEncoded: false)] = Data("different".utf8)

        // WHEN
        let shouldResolve = try runner.shouldResolve(sampleDependency, asset: sampleAsset)

        // THEN
        #expect(shouldResolve == true)
    }

    @Test("markAsResolved creates hash file with correct content")
    func markAsResolved_createsHashFile() async throws {
        // GIVEN
        let runner = makeRunner()

        // WHEN
        try runner.markAsResolved(sampleDependency, asset: sampleAsset)

        // THEN
        let hashURL = try runner.outputDirectoryHashFile(for: sampleDependency, asset: sampleAsset)

        // check if the hash file was created and contains valid hash data
        let hashData = fileManager.contents[hashURL.path(percentEncoded: false)]
        #expect(hashData == Data("abc123".utf8))
    }

    @Test("isFileDownloaded returns false if file not present")
    func isFileDownloaded_fileMissing() async throws {
        // GIVEN
        let runner = makeRunner()

        // WHEN
        let result = try runner.isFileDownloaded(for: sampleDependency, asset: sampleAsset)

        // THEN
        #expect(result == false)
    }

    @Test("isFileDownloaded returns true if present and checksum matches")
    func isFileDownloaded_success() async throws {
        // GIVEN
        let runner = makeRunner()

        let zipFileURL = runner.downloadURL(for: sampleDependency, asset: sampleAsset)
        // .zip file exists
        fileManager.existingFiles.insert(zipFileURL.path(percentEncoded: false))
        // checksum is correct
        checksumCalculatorMock.checksums[zipFileURL] = sampleAsset.checksum

        // WHEN
        let result = try runner.isFileDownloaded(for: sampleDependency, asset: sampleAsset)

        // THEN
        #expect(result == true)
    }
}
