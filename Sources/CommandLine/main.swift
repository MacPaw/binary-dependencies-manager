import ArgumentParser
import Foundation

// Making sure that output will be shown immediately, as it comes in the script
#if os(macOS)
setbuf(__stdoutp, nil)
#elseif os(Linux)
setbuf(stdout, nil)
#endif

struct BinaryDependenciesManager: ParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: "Dependencies resolver",
        subcommands: [
            ResolveCommand.self,
            CleanCommand.self,
        ],
        defaultSubcommand: nil
    )
}

BinaryDependenciesManager.main()
