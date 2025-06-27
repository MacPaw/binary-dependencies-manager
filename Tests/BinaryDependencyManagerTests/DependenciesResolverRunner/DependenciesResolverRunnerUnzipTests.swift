import Testing
import Foundation
@testable import BinaryDependencyManager
import Utils

@Suite("DependenciesResolverRunner Unzip Method Tests")
final class DependenciesResolverRunnerUnzipTests {
    let sampleDependency: Dependency = Dependency(
        repo: "org/repo",
        tag: "1.0.0",
        assets: [
            Dependency.Asset(
                checksum: "abc123",
                pattern: "asset.zip",
                contents: "Frameworks",
                outputDirectory: "Output"
            )
        ]
    )

    let tempDir: URL = {
        FileManager.default.temporaryDirectory
            .appending(components: "binary-dependency-manager-tests", UUID().uuidString, directoryHint: .isDirectory)
    }()
    
    lazy var sampleAsset = sampleDependency.assets[0]
    lazy var fileManager = FileManagerProtocolMock(tempDir: tempDir)
    lazy var unarchiverMock = UnarchiverProtocolMock()
    lazy var runner = makeRunner(fileManager: fileManager, unarchiverMock: unarchiverMock)
    

    func makeRunner(
        fileManager: FileManagerProtocolMock = FileManagerProtocolMock(),
        dependencies: [Dependency]? = nil,
        unarchiverMock: UnarchiverProtocolMock = UnarchiverProtocolMock()
    ) -> DependenciesResolverRunner {
        DependenciesResolverRunner.mock(
            dependencies: dependencies ?? [sampleDependency],
            outputDirectoryURL: tempDir.appending(path: "output", directoryHint: .isDirectory),
            cacheDirectoryURL: tempDir.appending(path: "cache", directoryHint: .isDirectory),
            fileManager: fileManager,
            uuidString: "mock-uuid",
            unarchiver: unarchiverMock
        )
    }

    @discardableResult
    func setupFileManagerForUnzip(
        asset: Dependency.Asset,
        tempContents: [String] = ["Library.framework", "Info.plist"]
    ) -> URL {
        let privateURLs = fileManager.privateDownloadsDirectoryURL
        let unzipingDirectory: URL = privateURLs.appending(path: "mock-uuid", directoryHint: .isDirectory)

        // Make shouldResolve return true (no hash file exists)
        // This is the default behavior when hash file doesn't exist

        // Set up temp directory contents after unzipping
        fileManager.directoryContents = [
            unzipingDirectory.appending(path: asset.contents ?? "", directoryHint: .isDirectory).path(percentEncoded: false): tempContents
        ]
        return unzipingDirectory
    }

    @Test("unzip skips when shouldResolve returns false")
    func unzip_skipsWhenShouldResolveReturnsFalse() async throws {
        // GIVEN

        // Set up hash file to make shouldResolve return false
        let hashURL = try runner.outputDirectoryHashFile(for: sampleDependency, asset: sampleAsset)
        fileManager.contents[hashURL.path(percentEncoded: false)] = Data(sampleAsset.checksum.utf8)

        // WHEN
        try runner.unzip(sampleDependency, asset: sampleAsset)

        // THEN
        // Verify unarchiver was not called
        #expect(unarchiverMock.unzipCalls.count == 0)
    }

    @Test("unzip creates temp directory and calls unarchiver")
    func unzip_createsDirectoryAndCallsUnarchiver() async throws {
        // GIVEN
        let unzippingDirectory = setupFileManagerForUnzip(asset: sampleAsset)

        // WHEN
        try runner.unzip(sampleDependency, asset: sampleAsset)

        // THEN
        // Verify temp directory was created
        #expect(fileManager.createdDirectories.contains(unzippingDirectory))

        // Verify unarchiver was called with correct parameters
        #expect(unarchiverMock.unzipCalls.count == 1)
        let unzipCall = unarchiverMock.unzipCalls[0]
        let downloadURL = runner.downloadURL(for: sampleDependency, asset: sampleAsset)
        #expect(unzipCall.archivePath == downloadURL.path(percentEncoded: false))
        #expect(
            unzipCall.outputFilePath == fileManager.privateDownloadsDirectoryURL
                .appending(path: runner.uuidString, directoryHint: .isDirectory)
                .path(percentEncoded: false)
        )
    }

    @Test("unzip copies files from temp to output directory")
    func unzip_copiesFilesToOutput() async throws {
        // GIVEN
                
        let tempContents = ["Library.framework", "Info.plist"]

        let unzippingDirectory = setupFileManagerForUnzip(asset: sampleAsset, tempContents: tempContents)

        // WHEN
        try runner.unzip(sampleDependency, asset: sampleAsset)

        // THEN
        // Verify output directory was created
        let outputDir = runner.outputDirectoryURL(for: sampleDependency, asset: sampleAsset)
        #expect(fileManager.createdDirectories.contains(outputDir))

        // Verify files were copied
        let contentsDir = unzippingDirectory.appending(path: sampleAsset.contents ?? "", directoryHint: .isDirectory)
        for item in tempContents {
            let sourceURL = contentsDir.appending(path: item, directoryHint: .notDirectory)
            let destinationURL = outputDir.appending(path: item, directoryHint: .notDirectory)
            #expect(fileManager.copiedFiles[sourceURL] == destinationURL)
        }
    }

    @Test("unzip removes existing files before copying")
    func unzip_removesExistingFiles() async throws {
        // GIVEN
                
        let tempContents = ["Library.framework"]

        setupFileManagerForUnzip(asset: sampleAsset, tempContents: tempContents)

        // Set up existing file in output directory
        let outputDir = runner.outputDirectoryURL(for: sampleDependency, asset: sampleAsset)
        let existingFileURL = outputDir.appending(path: "Library.framework", directoryHint: .notDirectory)
        fileManager.existingFiles.insert(existingFileURL.path(percentEncoded: false))

        // WHEN
        try runner.unzip(sampleDependency, asset: sampleAsset)

        // THEN
        // Verify existing file was removed
        #expect(fileManager.removedItems.contains(existingFileURL))
    }

    @Test("unzip cleans up temporary directory")
    func unzip_cleansUpTempDirectory() async throws {
        // GIVEN
        setupFileManagerForUnzip(asset: sampleAsset)

        // WHEN
        try runner.unzip(sampleDependency, asset: sampleAsset)

        // THEN
        // Verify temp root directory was removed
        let tempRootDir = fileManager.privateDownloadsDirectoryURL
        #expect(fileManager.removedItems.contains(tempRootDir))
    }

    @Test("unzip handles asset without contents directory")
    func unzip_handlesAssetWithoutContents() async throws {
        // GIVEN
        let assetWithoutContents = Dependency.Asset(
            checksum: "def456",
            pattern: "simple.zip",
            contents: nil,
            outputDirectory: "SimpleOutput"
        )
        let dependencyWithoutContents = Dependency(
            repo: "simple/repo",
            tag: "1.0.0",
            assets: [assetWithoutContents]
        )
        
        let runner = makeRunner(
            fileManager: fileManager,
            dependencies: [dependencyWithoutContents],
            unarchiverMock: unarchiverMock
        )

        // Set up temp directory contents (no subdirectory)
        let tempRootDir = tempDir.appending(
            components: "PrivateDownloads", "mock-uuid", assetWithoutContents.contents ?? "",
            directoryHint: .isDirectory
        )
        fileManager.directoryContents = [
            tempRootDir.path(percentEncoded: false): ["file1.txt", "file2.txt"]
        ]

        // WHEN
        try runner.unzip(dependencyWithoutContents, asset: assetWithoutContents)

        // THEN
        // Verify unarchiver was called
        #expect(unarchiverMock.unzipCalls.count == 1)

        // Verify both files are copied from temp root (no contents subdirectory)
        let outputDir = runner.outputDirectoryURL(for: dependencyWithoutContents, asset: assetWithoutContents)
        let sourceURL1 = tempRootDir.appending(path: "file1.txt", directoryHint: .notDirectory)
        let destURL1 = outputDir.appending(path: "file1.txt", directoryHint: .notDirectory)
        let sourceURL2 = tempRootDir.appending(path: "file2.txt", directoryHint: .notDirectory)
        let destURL2 = outputDir.appending(path: "file2.txt", directoryHint: .notDirectory)
        #expect(fileManager.copiedFiles[sourceURL1] == destURL1)
        #expect(fileManager.copiedFiles[sourceURL2] == destURL2)
    }
    
    func stubUnarchiverError(_ error: Error) {
        self.unarchiverMock = UnarchiverProtocolMock(errorToThrow: error)
    }

    @Test("unzip propagates unarchiver errors")
    func unzip_propagatesUnarchiverErrors() async throws {
        // GIVEN
        stubUnarchiverError(GenericError("Unzip failed"))

        // WHEN & THEN
        #expect(throws: Error.self) {
            try runner.unzip(sampleDependency, asset: sampleAsset)
        }

        // Verify unarchiver was called
        #expect(unarchiverMock.unzipCalls.count == 1)

        // Verify temp directory cleanup still happens even on error
        let tempRootDir = fileManager.temporaryDirectory.appending(path: "PrivateDownloads", directoryHint: .isDirectory)
        #expect(fileManager.removedItems.contains(tempRootDir))
    }

    @Test("unzip removes temporary files after copying")
    func unzip_removesTemporaryFilesAfterCopying() async throws {
        // GIVEN
                
        let tempContents = ["Library.framework"]

        let unzpipingDirectory = setupFileManagerForUnzip(asset: sampleAsset, tempContents: tempContents)

        // WHEN
        try runner.unzip(sampleDependency, asset: sampleAsset)

        // THEN
        // Verify temporary files were removed after copying
        let contentsDir = unzpipingDirectory.appending(path: sampleAsset.contents ?? "", directoryHint: .isDirectory)
        let tempFileURL = contentsDir.appending(path: "Library.framework", directoryHint: .notDirectory)
        #expect(fileManager.removedItems.contains(tempFileURL))
    }
}
