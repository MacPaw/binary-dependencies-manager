// Create a mock class for BinaryDependenciesDownloader
import Foundation
@testable import BinaryDependencyManager

final class BinaryDependenciesDownloaderMock: BinaryDependenciesDownloader {
    private(set) var downloadReleaseAssetCalls: [(repo: String?, tag: String?, pattern: String?, outputFilePath: String?)] = []

    public var throwError: Error?

    public init(throwError: Error? = .none) {
        self.throwError = throwError
    }

    public func downloadReleaseAsset(
        repo: String,
        tag: String,
        pattern: String?,
        outputFilePath: String
    ) throws {
        downloadReleaseAssetCalls.append((repo: repo, tag: tag, pattern: pattern, outputFilePath: outputFilePath))
        if let error = throwError {
            throw error
        }
    }
}
