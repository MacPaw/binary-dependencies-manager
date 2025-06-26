
import Foundation
import Utils

public protocol ChecksumCalculatorProtocol {
    func calculateChecksum(fileURL: URL) throws -> String
}

extension SHA256ChecksumCalculator: ChecksumCalculatorProtocol {}
