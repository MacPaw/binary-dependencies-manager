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

    @Test("asFilename removes invalid characters and replaces spaces with underscores")
    func test_asFilename_removesInvalidCharacters() async throws {
        // GIVEN
        let filename = "Report: 2025/06/25 final*version.txt"

        // WHEN
        let sanitized = filename.asFilename

        // THEN
        #expect(sanitized == "Report__2025_06_25_final_version_txt", "Invalid chars should be replaced")
    }

    @Test("asFilename works with only valid characters")
    func test_asFilename_withValidCharacters() async throws {
        // GIVEN
        let valid = "hello_world_123"

        // WHEN
        let result = valid.asFilename

        // THEN
        #expect(result == valid, "Valid string should stay the same")
    }

    @Test("asFilename handles empty string")
    func test_asFilename_withEmptyString() async throws {
        // GIVEN
        let empty = ""

        // WHEN
        let result = empty.asFilename

        // THEN
        #expect(result == "", "Empty string should stay empty")
    }

    @Test("asFilename handles all-invalid characters")
    func test_asFilename_allInvalid() async throws {
        // GIVEN
        let bad = "<>:/?*|"

        // WHEN
        let sanitized = bad.asFilename

        // THEN
        #expect(sanitized == "_______", "All-invalid string becomes a plain underscore string")
    }
}
