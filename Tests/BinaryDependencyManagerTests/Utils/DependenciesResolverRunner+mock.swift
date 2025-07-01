@testable import BinaryDependencyManager
import Foundation

extension DependenciesResolverRunner {
    static func mock(
        dependencies: [Dependency],
        outputDirectoryURL: URL,
        cacheDirectoryURL: URL,
        fileManager: FileManagerProtocol = FileManagerProtocolMock(),
        uuidString: String = UUID().uuidString,
        dependenciesDownloader: any BinaryDependenciesDownloader = BinaryDependenciesDownloaderMock(),
        unarchiver: any UnarchiverProtocol = UnarchiverProtocolMock(),
        checksumCalculator: any ChecksumCalculatorProtocol = ChecksumCalculatorProtocolMock()
    ) -> Self {
        self.init(
            dependencies: dependencies,
            outputDirectoryURL: outputDirectoryURL,
            cacheDirectoryURL: cacheDirectoryURL,
            fileManager: fileManager,
            uuidString: uuidString,
            dependenciesDownloader: dependenciesDownloader,
            unarchiver: unarchiver,
            checksumCalculator: checksumCalculator
        )
    }
}
