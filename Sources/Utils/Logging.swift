import Foundation

public enum Logger {
    /// When `true`, `verbose(_:)` messages are printed. Set once at startup from the CLI.
    nonisolated(unsafe) public static var isVerbose = false

    public static func log(_ message: String) {
        // extract [(.^] from the message)] and print it with green
        let message = message
            .replacingOccurrences(of: #"(\[.*?\])"#, with: "$1".green, options: .regularExpression)
            .replacingOccurrences(of: #"#(.*?)#"#, with: "[$1]".yellow, options: .regularExpression)

        print(message)
    }

    /// Logs a diagnostic message that is only printed when verbose output is enabled.
    /// - Parameter message: The message to log, evaluated lazily so it costs nothing when verbose is off.
    public static func verbose(_ message: @autoclosure () -> String) {
        guard isVerbose else { return }
        log(message())
    }
}
