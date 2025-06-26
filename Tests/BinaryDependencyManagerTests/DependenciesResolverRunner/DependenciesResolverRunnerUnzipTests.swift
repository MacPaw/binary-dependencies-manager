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
            .appending(pathComponents: "binary-dependency-manager-tests", UUID().uuidString, isDirectory: true)
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
            outputDirectoryURL: tempDir.appending(pathComponents: "output", isDirectory: true),
            cacheDirectoryURL: tempDir.appending(pathComponents: "cache", isDirectory: true),
            fileManager: fileManager,
            uuidString: "mock-uuid",
            unarchiver: unarchiverMock
        )
    }

    func setupFileManagerForUnzip(
        asset: Dependency.Asset,
        tempContents: [String] = ["Library.framework", "Info.plist"]
    ) {
        // Make shouldResolve return true (no hash file exists)
        // This is the default behavior when hash file doesn't exist

        // Set up temp directory contents after unzipping
        fileManager.directoryContents = [
            tempDir.appending(pathComponents: "PrivateDownloads", "mock-uuid", asset.contents ?? "", isDirectory: true).filePath: tempContents
        ]
    }

    @Test("unzip skips when shouldResolve returns false")
    func unzip_skipsWhenShouldResolveReturnsFalse() async throws {
        // GIVEN

        // Set up hash file to make shouldResolve return false
        let hashURL = try runner.outputDirectoryHashFile(for: sampleDependency, asset: sampleAsset)
        fileManager.contents[hashURL.filePath] = Data(sampleAsset.checksum.utf8)

        // WHEN
        try runner.unzip(sampleDependency, asset: sampleAsset)

        // THEN
        // Verify unarchiver was not called
        #expect(unarchiverMock.unzipCalls.count == 0)
    }

    @Test("unzip creates temp directory and calls unarchiver")
    func unzip_createsDirectoryAndCallsUnarchiver() async throws {
        // GIVEN
                

        setupFileManagerForUnzip(asset: sampleAsset)

        // WHEN
        try runner.unzip(sampleDependency, asset: sampleAsset)

        // THEN
        // Verify temp directory was created
        let tempDir = fileManager.temporaryDirectory.appending(pathComponents: "PrivateDownloads", "mock-uuid", isDirectory: true)
        #expect(fileManager.createdDirectories.contains(tempDir))

        // Verify unarchiver was called with correct parameters
        #expect(unarchiverMock.unzipCalls.count == 1)
        let unzipCall = unarchiverMock.unzipCalls[0]
        let downloadURL = runner.downloadURL(for: sampleDependency, asset: sampleAsset)
        #expect(unzipCall.archivePath == downloadURL.filePath)
        #expect(unzipCall.outputFilePath == tempDir.filePath)
    }

    @Test("unzip copies files from temp to output directory")
    func unzip_copiesFilesToOutput() async throws {
        // GIVEN
                
        let tempContents = ["Library.framework", "Info.plist"]

        setupFileManagerForUnzip(asset: sampleAsset, tempContents: tempContents)

        // WHEN
        try runner.unzip(sampleDependency, asset: sampleAsset)

        // THEN
        // Verify output directory was created
        let outputDir = runner.outputDirectoryURL(for: sampleDependency, asset: sampleAsset)
        #expect(fileManager.createdDirectories.contains(outputDir))

        // Verify files were copied
        let contentsDir = fileManager.temporaryDirectory.appending(pathComponents: "PrivateDownloads", "mock-uuid", sampleAsset.contents ?? "", isDirectory: true)
        for item in tempContents {
            let sourceURL = contentsDir.appending(pathComponents: item, isDirectory: false)
            let destinationURL = outputDir.appending(pathComponents: item, isDirectory: false)
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
        let existingFileURL = outputDir.appending(pathComponents: "Library.framework", isDirectory: false)
        fileManager.existingFiles.insert(existingFileURL.filePath)

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
        let tempRootDir = fileManager.temporaryDirectory.appending(pathComponents: "PrivateDownloads", isDirectory: true)
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
        let tempRootDir = tempDir.appending(pathComponents: "PrivateDownloads", "mock-uuid", isDirectory: true)
        fileManager.directoryContents = [
            tempRootDir.filePath: ["file1.txt", "file2.txt"]
        ]

        // WHEN
        try runner.unzip(dependencyWithoutContents, asset: assetWithoutContents)

        // THEN
        // Verify unarchiver was called
        #expect(unarchiverMock.unzipCalls.count == 1)

        // Verify files were copied from temp root (no contents subdirectory)
        let outputDir = runner.outputDirectoryURL(for: dependencyWithoutContents, asset: assetWithoutContents)
        let sourceURL1 = tempRootDir.appending(pathComponents: "file1.txt", isDirectory: false)
        let destURL1 = outputDir.appending(pathComponents: "file1.txt", isDirectory: false)
        #expect(fileManager.copiedFiles[sourceURL1] == destURL1)
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
        let tempRootDir = fileManager.temporaryDirectory.appending(pathComponents: "PrivateDownloads", isDirectory: true)
        #expect(fileManager.removedItems.contains(tempRootDir))
    }

    @Test("unzip removes temporary files after copying")
    func unzip_removesTemporaryFilesAfterCopying() async throws {
        // GIVEN
                
        let tempContents = ["Library.framework"]

        setupFileManagerForUnzip(asset: sampleAsset, tempContents: tempContents)

        // WHEN
        try runner.unzip(sampleDependency, asset: sampleAsset)

        // THEN
        // Verify temporary files were removed after copying
        let contentsDir = fileManager.temporaryDirectory.appending(pathComponents: "PrivateDownloads", "mock-uuid", sampleAsset.contents ?? "", isDirectory: true)
        let tempFileURL = contentsDir.appending(pathComponents: "Library.framework", isDirectory: false)
        #expect(fileManager.removedItems.contains(tempFileURL))
    }
}
