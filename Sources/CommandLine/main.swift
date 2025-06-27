import ArgumentParser
import Foundation
import Utils

// Making sure that output will be shown immediately, as it comes in the script
#if os(macOS)
setbuf(__stdoutp, nil)
#elseif os(Linux)
@preconcurrency import Glibc // https://github.com/swiftlang/swift/issues/77866

setbuf(stdout, nil)
#endif

struct BinaryDependenciesManager: ArgumentParser.ParsableCommand {
    /// The version of the binary dependencies manager.
    static let version: Version = "0.0.4"

    static let configuration = CommandConfiguration(
        abstract: "Binary dependencies resolver",
        version: version.description,
        subcommands: [
            ResolveCommand.self,
            CleanCommand.self,
        ],
        defaultSubcommand: nil
    )
}

BinaryDependenciesManager.main()
