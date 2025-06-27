import Testing
import Foundation
@testable import BinaryDependencyManager
import Utils

@Suite("DependenciesResolverRunner Download Method Tests")
struct DependenciesResolverRunnerDownloadTests {
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
            .appending(components: "binary-dependency-manager-tests", UUID().uuidString, directoryHint: .isDirectory)
    }()
    
    func makeRunner(
        fileManager: FileManagerProtocolMock = FileManagerProtocolMock(),
        dependencies: [Dependency]? = nil,
        downloaderMock: BinaryDependenciesDownloaderMock = BinaryDependenciesDownloaderMock(),
        checksumCalculatorMock: ChecksumCalculatorProtocolMock = ChecksumCalculatorProtocolMock()
    ) -> DependenciesResolverRunner {
        DependenciesResolverRunner.mock(
            dependencies: dependencies ?? [sampleDependency],
            outputDirectoryURL: tempDir.appending(path: "output", directoryHint: .isDirectory),
            cacheDirectoryURL: tempDir.appending(path: "cache", directoryHint: .isDirectory),
            fileManager: fileManager,
            uuidString: "mock-uuid",
            dependenciesDownloader: downloaderMock,
            checksumCalculator: checksumCalculatorMock
        )
    }
    
    @Test("download creates directory and downloads file when not already downloaded")
    func download_success() async throws {
        // GIVEN
        let fileManager = FileManagerProtocolMock(tempDir: tempDir)
        let downloaderMock = BinaryDependenciesDownloaderMock()
        let checksumCalculatorMock = ChecksumCalculatorProtocolMock()
        let runner = makeRunner(
            fileManager: fileManager,
            downloaderMock: downloaderMock,
            checksumCalculatorMock: checksumCalculatorMock
        )
        let sampleAsset = sampleDependency.assets[0]
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
        let fileManager = FileManagerProtocolMock(tempDir: tempDir)
        let downloaderMock = BinaryDependenciesDownloaderMock()
        let checksumCalculatorMock = ChecksumCalculatorProtocolMock()
        let runner = makeRunner(
            fileManager: fileManager,
            downloaderMock: downloaderMock,
            checksumCalculatorMock: checksumCalculatorMock
        )
        let sampleAsset = sampleDependency.assets[0]
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
        let fileManager = FileManagerProtocolMock(tempDir: tempDir)
        let downloaderMock = BinaryDependenciesDownloaderMock()
        let checksumCalculatorMock = ChecksumCalculatorProtocolMock()
        let runner = makeRunner(
            fileManager: fileManager,
            downloaderMock: downloaderMock,
            checksumCalculatorMock: checksumCalculatorMock
        )
        let sampleAsset = sampleDependency.assets[0]
        let downloadURL = runner.downloadURL(for: sampleDependency, asset: sampleAsset)
        
        // Set up checksum calculation to return wrong checksum
        checksumCalculatorMock.checksums[downloadURL] = "wrong_checksum"
        
        // WHEN & THEN
        #expect(throws: Error.self) {
            try runner.download(sampleDependency, asset: sampleAsset, with: downloaderMock)
        }
        
        // Verify downloader was called
        #expect(downloaderMock.downloadReleaseAssetCalls.count == 1)
    }
    
    @Test("download redownloads when existing file has wrong checksum")
    func download_redownloadsOnChecksumMismatch() async throws {
        // GIVEN
        let fileManager = FileManagerProtocolMock(tempDir: tempDir)
        let downloaderMock = BinaryDependenciesDownloaderMock()
        let checksumCalculatorMock = ChecksumCalculatorProtocolMock()
        let runner = makeRunner(
            fileManager: fileManager,
            downloaderMock: downloaderMock,
            checksumCalculatorMock: checksumCalculatorMock
        )
        let sampleAsset = sampleDependency.assets[0]
        let downloadURL = runner.downloadURL(for: sampleDependency, asset: sampleAsset)
        
        // File already exists
        fileManager.existingFiles.insert(downloadURL.path(percentEncoded: false))
        // First checksum call returns wrong checksum, second returns correct
        checksumCalculatorMock.checksums[downloadURL] = "wrong_checksum"
        
        // WHEN & THEN
        #expect(throws: Error.self) {
            try runner.download(sampleDependency, asset: sampleAsset, with: downloaderMock)
        }
        
        // Verify file was removed due to checksum mismatch
        #expect(fileManager.removedItems.contains(downloadURL))
        
        // Verify downloader was called
        #expect(downloaderMock.downloadReleaseAssetCalls.count == 1)
    }
    
    @Test("download propagates downloader errors")
    func download_propagatesDownloaderErrors() async throws {
        // GIVEN
        let fileManager = FileManagerProtocolMock(tempDir: tempDir)
        let downloaderMock = BinaryDependenciesDownloaderMock(throwError: GenericError("Download failed"))
        let checksumCalculatorMock = ChecksumCalculatorProtocolMock()
        let runner = makeRunner(
            fileManager: fileManager,
            downloaderMock: downloaderMock,
            checksumCalculatorMock: checksumCalculatorMock
        )
        let sampleAsset = sampleDependency.assets[0]
        
        // WHEN & THEN
        #expect(throws: Error.self) {
            try runner.download(sampleDependency, asset: sampleAsset, with: downloaderMock)
        }
        
        // Verify downloader was called
        #expect(downloaderMock.downloadReleaseAssetCalls.count == 1)
    }
    
    @Test("download propagates checksum calculation errors")
    func download_propagatesChecksumErrors() async throws {
        // GIVEN
        let fileManager = FileManagerProtocolMock(tempDir: tempDir)
        let downloaderMock = BinaryDependenciesDownloaderMock()
        let checksumCalculatorMock = ChecksumCalculatorProtocolMock(errorToThrow: GenericError("Checksum calculation failed"))
        let runner = makeRunner(
            fileManager: fileManager,
            downloaderMock: downloaderMock,
            checksumCalculatorMock: checksumCalculatorMock
        )
        let sampleAsset = sampleDependency.assets[0]
        
        // WHEN & THEN
        #expect(throws: Error.self) {
            try runner.download(sampleDependency, asset: sampleAsset, with: downloaderMock)
        }
        
        // Verify downloader was called
        #expect(downloaderMock.downloadReleaseAssetCalls.count == 1)
    }
}
