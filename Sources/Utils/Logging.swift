import Foundation

public enum Logger {
    public static func log(_ message: String) {
        // extract [(.^] from the message)] and print it with green
        let message = message
            .replacingOccurrences(of: #"(\[.*?\])"#, with: "$1".green, options: .regularExpression)
            .replacingOccurrences(of: #"#(.*?)#"#, with: "[$1]".yellow, options: .regularExpression)

        print(message)
    }
}
