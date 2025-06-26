import Crypto
import Foundation

public struct SHA256ChecksumCalculator {
    public init() {}

    public func calculateChecksum(fileURL: URL) throws -> String {
        // Read the file in chunks to avoid RAM usage issues

        let handle: FileHandle = try FileHandle(forReadingFrom: fileURL)
        var hasher: SHA256 = SHA256()

        #if os(macOS)

        while autoreleasepool(invoking: {
            let nextChunk = handle.readData(ofLength: 1024 * 1024)
            guard !nextChunk.isEmpty else { return false }
            hasher.update(data: nextChunk)
            return true
        }) {}

        #elseif os(Linux)

        var eof: Bool = false
        var nextChunk: Data

        while !eof {
            nextChunk = handle.readData(ofLength: 1024 * 1024)
            eof = nextChunk.isEmpty
            if !eof {
                hasher.update(data: nextChunk)
            }
        }

        #endif

        let digest: SHA256.Digest = hasher.finalize()

        return digest.hexadecimalString
    }
}

extension SHA256.Digest {
    fileprivate var hexadecimalString: String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}
