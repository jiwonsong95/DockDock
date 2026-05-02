import Foundation

enum DockPreferencesService {
    static func applyRecommendedAutohideSettings() throws {
        try run("/usr/bin/defaults", arguments: ["write", "com.apple.dock", "autohide", "-bool", "true"])
        try run("/usr/bin/defaults", arguments: ["write", "com.apple.dock", "autohide-delay", "-float", "0"])
        try run("/usr/bin/defaults", arguments: ["write", "com.apple.dock", "autohide-time-modifier", "-float", "0"])
        try run("/usr/bin/killall", arguments: ["Dock"])
    }

    private static func run(_ executablePath: String, arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let stderr = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let message = stderr?.isEmpty == false ? stderr! : "Command exited with status \(process.terminationStatus)."
            throw DockPreferencesError.commandFailed(message)
        }
    }
}

enum DockPreferencesError: LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return message
        }
    }
}
