import ArgumentParser
import Foundation
import Utils

// Making sure that output will be shown immediately, as it comes in the script
#if os(macOS)
setbuf(__stdoutp, nil)
#elseif os(Linux)
setbuf(stdout, nil)
#endif

struct BinaryDependenciesManager: ArgumentParser.ParsableCommand {
    /// The version of the binary dependencies manager.
    static var version: Version = "0.0.4"

    static var configuration = CommandConfiguration(
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
