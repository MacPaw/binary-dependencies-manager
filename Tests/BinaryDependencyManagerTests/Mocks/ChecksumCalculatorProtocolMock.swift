import Foundation

@testable import BinaryDependencyManager
import Utils

/// Mock implementation for UnarchiverProtocol for use in unit tests.
class ChecksumCalculatorProtocolMock: ChecksumCalculatorProtocol {
    /// Records the arguments with which unzip was called.
    public private(set) var unzipCalls: [(archivePath: String, outputFilePath: String)] = []
    /// If set, unzip will throw this error when called.
    public var errorToThrow: Error?

    public init(errorToThrow: Error? = nil) {
        self.errorToThrow = errorToThrow
    }

    var checksums: [URL: String] = [:]
    var checksumCalls: [URL] = []
    public func calculateChecksum(fileURL: URL) throws -> String {
        checksumCalls.append(fileURL)
        if let errorToThrow {
            throw errorToThrow
        }
        guard let checksum = checksums[fileURL] else {
            throw GenericError("no checksum provided for \(fileURL.relativeFilePath)")
        }
        return checksum
    }
}
