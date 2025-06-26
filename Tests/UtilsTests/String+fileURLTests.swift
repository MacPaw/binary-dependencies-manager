import Foundation
import Testing

@Suite("String+fileURL Tests")
struct StringFileURLExtensionTests {
    @Test("asFileURL returns standardized absolute file URL on supported platform")
    func test_asFileURL_standardizesPath() async throws {
        // GIVEN
        let testPath = "/tmp/../tmp/file.txt"

        // WHEN
        let url = testPath.asFileURL

        // THEN
        #expect(url.isFileURL, "Should be a file URL")
        #expect(url.path == "/tmp/file.txt", "Path should be standardized")
    }

    @Test("asFileURL produces the same result as URL(fileURLWithPath:) for legacy platforms")
    func test_asFileURL_legacyCompatibility() async throws {
        // GIVEN
        let testPath = "/Users/test/testfile"

        // WHEN
        let expected = URL(fileURLWithPath: testPath).standardizedFileURL.absoluteURL
        let actual = testPath.asFileURL

        // THEN
        #expect(actual == expected, "Should match legacy URL construction")
    }
}
