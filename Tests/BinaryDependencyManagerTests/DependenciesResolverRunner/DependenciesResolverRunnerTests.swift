import Testing
import Foundation
@testable import BinaryDependencyManager
import Utils

@Suite("DependenciesResolverRunner tests")
final class DependenciesResolverRunnerTests {
    var sampleAsset = Dependency.Asset(
        checksum: "abc123",
        pattern: "asset.zip",
        contents: nil,
        outputDirectory: nil
    )

    lazy var sampleDependency: Dependency = Dependency(
        repo: "org/repo",
        tag: "1.0.0",
        assets: [
            sampleAsset,
        ]
    )

    lazy var fileManager = FileManagerProtocolMock(tempDir: tempDir)
    let downloaderMock = BinaryDependenciesDownloaderMock()
    let checksumCalculatorMock = ChecksumCalculatorProtocolMock()

    let tempDir: URL = {
        FileManager.default.temporaryDirectory
            .appending(components: "binary-dependency-manager-tests", "\(UUID().uuidString) space", directoryHint: .isDirectory)
    }()

    let outputRelativePath = "output"
    let cacheRelativePath = "cache"

    func makeRunner(
        sampleAsset: Dependency.Asset? = .none,
        outputPath: String? = .none,
        cachePath: String? = .none
    ) -> DependenciesResolverRunner {
        if let sampleAsset = sampleAsset {
            self.sampleAsset = sampleAsset
            self.sampleDependency = Dependency(
                repo: sampleDependency.repo,
                tag: sampleDependency.tag,
                assets: [sampleAsset]
            )
        }
        return DependenciesResolverRunner.mock(
            dependencies: [sampleDependency],
            outputDirectoryURL: outputPath?.asFileURL ?? tempDir.appending(path: self.outputRelativePath, directoryHint: .isDirectory),
            cacheDirectoryURL: cachePath?.asFileURL ?? tempDir.appending(path: self.cacheRelativePath, directoryHint: .isDirectory),
            fileManager: fileManager,
            uuidString: "mock-uuid",
            dependenciesDownloader: downloaderMock,
            checksumCalculator: checksumCalculatorMock
        )
    }
}
