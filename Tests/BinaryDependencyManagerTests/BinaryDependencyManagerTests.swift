import BinaryDependencyManager

import XCTest

final class BinaryDependencyManagerTests: XCTestCase {
    func testExample() throws {
        _ = DependenciesResolverRunner(dependenciesJSONPath: "", cacheDirectoryPath: "", outputDirectoryPath: "")
    }
}
