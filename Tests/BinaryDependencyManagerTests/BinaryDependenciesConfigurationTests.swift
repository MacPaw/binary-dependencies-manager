@testable import binary_dependencies_manager
import XCTest
import Testing
import Yams
import Foundation

final class BinaryDependenciesConfigurationTests: XCTestCase {
    
    func testDecodingJSONShort() throws {
        let jsonString = """
            [
                {
                    "repo": "A", 
                    "tag": "0.0.1",
                    "pattern": "pattern1",
                    "checksum": "check1"
                },
                {
                    "repo": "B", 
                    "tag": "0.0.2",
                    "contents": "contents2",
                    "output": "output/directory2",
                    "checksum": "check2"
                }
            ]
            """

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BinaryDependenciesConfiguration.self, from: Data(jsonString.utf8))

        XCTAssertEqual(
            decoded,
            BinaryDependenciesConfiguration(
                dependencies: [
                    .init(
                        repo: "A",
                        tag: "0.0.1",
                        assets: [.init(checksum: "check1", pattern: "pattern1")]
                    ),
                    .init(
                        repo: "B",
                        tag: "0.0.2",
                        assets: [.init(checksum: "check2", contents: "contents2", outputDirectory: "output/directory2")]
                    )
                ]
            )
        )
    }

    func testDecodingYAMLFull() throws {
        let yamlString = """
            minimumVersion: 0.0.1
            outputDirectory: output/directory
            cacheDirectory: cache/directory
            dependencies:
              - repo: A
                tag: "0.0.1"
                pattern: pattern1
                checksum: "check1"
              - repo: B
                tag: 0.0.2
                assets:
                  - contents: contents2
                    output: output/directory2
                    checksum: check2
            """

        let decoder = YAMLDecoder()
        let decoded = try decoder.decode(BinaryDependenciesConfiguration.self, from: Data(yamlString.utf8))

        XCTAssertEqual(
            decoded,
            BinaryDependenciesConfiguration(
                minimumVersion: "0.0.1",
                outputDirectory: "output/directory",
                cacheDirectory: "cache/directory",
                dependencies: [
                    .init(
                        repo: "A",
                        tag: "0.0.1",
                        assets: [.init(checksum: "check1", pattern: "pattern1")]
                    ),
                    .init(
                        repo: "B",
                        tag: "0.0.2",
                        assets: [.init(checksum: "check2", contents: "contents2", outputDirectory: "output/directory2")]
                    )
                ]
            )
        )
    }
}
