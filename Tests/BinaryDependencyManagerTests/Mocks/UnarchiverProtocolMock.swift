import Foundation

@testable import BinaryDependencyManager

/// Mock implementation for UnarchiverProtocol for use in unit tests.
class UnarchiverProtocolMock: UnarchiverProtocol {
    /// Records the arguments with which unzip was called.
    public private(set) var unzipCalls: [(archivePath: String, outputFilePath: String)] = []
    /// If set, unzip will throw this error when called.
    public var errorToThrow: Error?
    
    public init(errorToThrow: Error? = nil) {
        self.errorToThrow = errorToThrow
    }
    
    public func unzip(
        archivePath: String,
        outputFilePath: String
    ) throws {
        unzipCalls.append((archivePath, outputFilePath))
        if let error = errorToThrow {
            throw error
        }
    }
}
