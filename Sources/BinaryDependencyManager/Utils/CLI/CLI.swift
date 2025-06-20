import Foundation

enum CLI {
    /// Returns path to the provided `cliToolName`.
    ///
    /// - Parameters:
    /// - `cliToolName`: A tool name to locate.
    static func which(cliToolName: String) throws -> URL {
        do {
            let cliPath = try run(executableURL: URL(fileURLWithPath: "/usr/bin/which"), arguments: [cliToolName])
            return URL(fileURLWithPath: cliPath)
        } catch {
            Logger.log("Error: \(error)".red)
            throw NSError(domain: "Can't find \(cliToolName) command line tool", code: 0)
        }
    }
    
    /// Returns stdout returned by the execution of `executableURL` with given `arguments`.
    /// - Parameters:
    ///   - executableURL: An URL to the executable to run.
    ///   - arguments: A list of arguments to pass to the executable invocation.
    ///   - currentDirectoryURL: A working directory URL where executable will be launched.
    @discardableResult
    static func run(executableURL: URL, arguments: [String], currentDirectoryURL: URL? = .none) throws -> String {
        Logger.log("[Run] \(executableURL.path) \(arguments.joined(separator: " "))")

        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let stdout = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw NSError(domain: "Can't parse output from the \(executableURL.path)", code: 0)
        }
        return stdout
    }
}
