import ArgumentParser
import Foundation

// Making sure that output will be shown immediately, as it comes in the script
setbuf(__stdoutp, nil)

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
