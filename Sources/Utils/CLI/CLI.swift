import Foundation

public enum CLI {
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
    public static func run(executableURL: URL, arguments: [String], currentDirectoryURL: URL? = .none) throws -> String {
        Logger.log("[Run] \(executableURL.path(percentEncoded: false)) \(arguments.joined(separator: " "))")

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        guard let stdout = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw GenericError("Can't parse stdout output from the \(executableURL.path(percentEncoded: false))")
        }

        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        guard let stderr = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw GenericError("Can't parse stderr output from the \(executableURL.path(percentEncoded: false))")
        }

        guard process.terminationStatus == 0 else {
            throw GenericError("Error running \(executableURL.path(percentEncoded: false)) with arguments \(arguments.joined(separator: " ")). Output:\n\(stdout).\nError:\n\(stderr).")
        }

        return stdout
    }
}
