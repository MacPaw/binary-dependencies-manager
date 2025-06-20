import ArgumentParser
import BinaryDependencyManager

struct ResolveCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "resolve")

    // Path to dependencies json
    @Option(name: .shortAndLong, help: "Path to dependencies json")
    var dependenciesJSONPath: String

    // Path to cache directory
    @Option(name: .shortAndLong, help: "Path to cache directory")
    var cacheDirectoryPath: String

    // Path to output directory
    @Option(name: .shortAndLong, help: "Path to output directory, where downloaded dependencies will be placed")
    var outputDirectoryPath: String

    func run() throws {
        let resolver = DependenciesResolverRunner(
            dependenciesJSONPath: dependenciesJSONPath,
            cacheDirectoryPath: cacheDirectoryPath,
            outputDirectoryPath: outputDirectoryPath
        )
        try resolver.run()
    }
}
