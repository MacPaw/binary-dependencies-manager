@testable import BinaryDependencyManager
import XCTest
import Utils
import Foundation

final class BinaryDependencyManagerTests: XCTestCase {
    func testFullInit() throws {
        _ = try DependenciesResolverRunner(
            dependencies: [],
            outputDirectoryURL: "".asFileURL,
            cacheDirectoryURL: "".asFileURL,
            fileManager: FileManager.default,
            uuidString: UUID().uuidString,
            dependenciesDownloader: CLI.GitHub(),
            unarchiver: CLI.Unzip(),
            checksumCalculator: SHA256ChecksumCalculator()
        )
    }
}
