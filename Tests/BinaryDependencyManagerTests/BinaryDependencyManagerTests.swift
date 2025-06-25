import BinaryDependencyManager

import XCTest

final class BinaryDependencyManagerTests: XCTestCase {
    func testExample() throws {
        _ = try DependenciesResolverRunner(
            dependencies: [],
            outputDirectoryURL: "".asFileURL,
            cacheDirectoryURL: "".asFileURL
        )
    }
}
