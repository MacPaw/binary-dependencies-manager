@testable import BinaryDependencyManager
import XCTest

final class DependencyTests: XCTestCase {
    private let dependency = Dependency(repo: "test/repo", tag: "1.0.0", assets: [])

    func test_info_withPattern() {
        let asset = makeAsset(pattern: "Asset.xcframework.zip")

        XCTAssertEqual(dependency.info(for: asset), "test/repo@1.0.0 Asset.xcframework.zip")
    }

    func test_info_withPatternAndOutputDirectory() {
        let asset = makeAsset(pattern: "Asset.framework.zip", outputDirectory: "sandbox")

        XCTAssertEqual(dependency.info(for: asset), "test/repo@1.0.0 Asset.framework.zip -> sandbox")
    }

    func test_info_withoutPattern_fallsBackToContents() {
        let asset = makeAsset(contents: "Products")

        XCTAssertEqual(dependency.info(for: asset), "test/repo@1.0.0 Products")
    }

    func test_info_patternTakesPrecedenceOverContents() {
        let asset = makeAsset(pattern: "Asset.zip", contents: "Products")

        XCTAssertEqual(dependency.info(for: asset), "test/repo@1.0.0 Asset.zip")
    }

    func test_info_withoutPatternOrContents() {
        let asset = makeAsset(pattern: nil, contents: nil)

        XCTAssertEqual(dependency.info(for: asset), "test/repo@1.0.0")
    }

    // MARK: - Private

    // The checksum does not affect `info(for:)`, so it is fixed here to keep the tests focused on formatting.
    private func makeAsset(
        pattern: String? = nil,
        contents: String? = nil,
        outputDirectory: String? = nil
    ) -> Dependency.Asset {
        Dependency.Asset(checksum: "checksum", pattern: pattern, contents: contents, outputDirectory: outputDirectory)
    }
}
