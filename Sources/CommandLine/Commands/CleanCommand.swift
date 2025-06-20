import ArgumentParser
import Foundation

struct CleanCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "clean")

    // Path to cache directory
    @Option(name: .shortAndLong, help: "Path to cache directory")
    var cacheDirectoryPath: String

    // Path to output directory
    @Option(name: .shortAndLong, help: "Path to output directory, where downloaded dependencies will be placed")
    var outputDirectoryPath: String

    func run() throws {
        Logger.log("#Cleanup# Removing \(outputDirectoryPath)")
        try? FileManager.default.removeItem(atPath: outputDirectoryPath)

        Logger.log("#Cleanup# Removing \(cacheDirectoryPath)")
        try? FileManager.default.removeItem(atPath: cacheDirectoryPath)
    }
}
