import XCTest
@testable import Utils

final class CLITests: XCTestCase {
    func testWhichFindsExistingTool() throws {
        let url = try CLI.which(cliToolName: "ls")
        XCTAssertTrue(url.path.hasSuffix("/ls"), "Should find 'ls' command")
    }

    func testWhichThrowsForNonexistentTool() {
        XCTAssertThrowsError(try CLI.which(cliToolName: "nonexistent_tool_12345")) { error in
            let nsError = error as NSError
            XCTAssertTrue(nsError.domain.contains("nonexistent_tool_12345"))
        }
    }
}
