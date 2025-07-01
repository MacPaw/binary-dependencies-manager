import Foundation
@testable import Utils
import Testing

@Suite("Version tests")
struct VersionTests {

    @Test
    func test_version_init() {
        let version = Version(1, 2, 3, prereleaseIdentifiers: ["alpha", "1"], buildMetadataIdentifiers: ["4"])

        // Same init is equal
        #expect(version == Version(1, 2, 3, prereleaseIdentifiers: ["alpha", "1"], buildMetadataIdentifiers: ["4"]))

        // Equal to ExpressibleByStringLiteral
        #expect(version == "1.2.3-alpha.1+4")

        // Stores values correctly
        #expect(version.major == 1)
        #expect(version.minor == 2)
        #expect(version.patch == 3)
        #expect(version.prereleaseIdentifiers == ["alpha", "1"])
        #expect(version.buildMetadataIdentifiers == ["4"])
    }

    @Test
    func test_version_compare() {

        // Metadata doesn't influence when comparing to release
        #expect(Version(1, 2, 3, buildMetadataIdentifiers: ["4"]) == "1.2.3")

        // Release is greater than pre-release
        #expect(Version(1, 2, 3) > "1.2.3-alpha.1+4")

        // Next versions are bigger
        #expect(Version(1, 2, 4) > "1.2.3")
        #expect(Version(1, 3, 3) > "1.2.3")
        #expect(Version(2, 2, 3) > "1.2.3")
    }
}
