import Testing
import Foundation
@testable import BinaryDependencyManager
import Utils

extension DependenciesResolverRunnerTests {
    @Test("download creates directory and downloads file when not already downloaded")
    func download_success() async throws {
        // GIVEN

        let runner = makeRunner()
        let downloadURL = runner.downloadURL(for: sampleDependency, asset: sampleAsset)
        
        // Set up checksum calculation to return the expected checksum
        checksumCalculatorMock.checksums[downloadURL] = sampleAsset.checksum
        
        // WHEN
        try runner.download(sampleDependency, asset: sampleAsset, with: downloaderMock)
        
        // THEN
        // Verify directory was created
        let downloadDir = runner.downloadDirectoryURL(for: sampleDependency, asset: sampleAsset)
        #expect(fileManager.createdDirectories.contains(downloadDir))
        
        // Verify downloader was called with correct parameters
        #expect(downloaderMock.downloadReleaseAssetCalls.count == 1)
        let downloadCall = downloaderMock.downloadReleaseAssetCalls[0]
        #expect(downloadCall.repo == sampleDependency.repo)
        #expect(downloadCall.tag == sampleDependency.tag)
        #expect(downloadCall.pattern == sampleAsset.pattern)
        #expect(downloadCall.outputFilePath == downloadURL.path(percentEncoded: false))
        
        // Verify checksum was calculated
        #expect(checksumCalculatorMock.checksumCalls.contains(downloadURL))
    }
    
    @Test("download skips download when file already exists with correct checksum")
    func download_skipsWhenAlreadyDownloaded() async throws {
        // GIVEN
        let runner = makeRunner()
        let downloadURL = runner.downloadURL(for: sampleDependency, asset: sampleAsset)
        
        // File already exists
        fileManager.existingFiles.insert(downloadURL.path(percentEncoded: false))
        // Checksum matches
        checksumCalculatorMock.checksums[downloadURL] = sampleAsset.checksum
        
        // WHEN
        try runner.download(sampleDependency, asset: sampleAsset, with: downloaderMock)
        
        // THEN
        // Verify downloader was not called
        #expect(downloaderMock.downloadReleaseAssetCalls.count == 0)
    }
    
    @Test("download throws error when checksums don't match")
    func download_throwsErrorOnChecksumMismatch() async throws {
        // GIVEN
        let runner = makeRunner()
        let downloadURL = runner.downloadURL(for: sampleDependency, asset: sampleAsset)
        
        // Set up checksum calculation to return wrong checksum
        let wrongChecksum = "wrong_checksum"
        checksumCalculatorMock.checksums[downloadURL] = wrongChecksum

        // WHEN & THEN
        // runner must throw
        let error = try #require(throws: GenericError.self) {
            try runner.download(sampleDependency, asset: sampleAsset, with: downloaderMock)
        }
        #expect(
            error.message.contains("Checksum is incorrect. \(wrongChecksum) != \(sampleAsset.checksum)"),
            "Thrown error describes invalid checksum"
        )

        // Verify check sum calc was called
        #expect(checksumCalculatorMock.checksumCalls.count == 1)
    }

    @Test("download propagates downloader errors")
    func download_propagatesDownloaderErrors() async throws {
        // GIVEN
        // Downloader throws error
        let downloadError = GenericError("Download failed")
        downloaderMock.throwError = downloadError

        let runner = makeRunner()

        // WHEN & THEN
        // runner must throw
        let error = try #require(throws: GenericError.self) {
            try runner.download(sampleDependency, asset: sampleAsset, with: downloaderMock)
        }
        #expect(error == downloadError, "thrown error by runner equals to the error thrown by downloader")

        // Verify downloader was called
        #expect(downloaderMock.downloadReleaseAssetCalls.count == 1)
    }
}
