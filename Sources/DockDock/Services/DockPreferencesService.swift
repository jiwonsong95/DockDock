import Foundation

enum DockPreferencesService {
    static func currentStatus() -> DockPreferencesStatus {
        CFPreferencesAppSynchronize("com.apple.dock" as CFString)
        let defaults = UserDefaults(suiteName: "com.apple.dock")
        let isAutoHideEnabled = defaults?.bool(forKey: "autohide") ?? false
        let revealDelay = defaults?.object(forKey: "autohide-delay") as? NSNumber
        let revealAnimationTime = defaults?.object(forKey: "autohide-time-modifier") as? NSNumber

        return DockPreferencesStatus(
            isAutoHideEnabled: isAutoHideEnabled,
            revealDelay: revealDelay?.doubleValue,
            revealAnimationTime: revealAnimationTime?.doubleValue
        )
    }

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

struct DockPreferencesStatus {
    var isAutoHideEnabled: Bool
    var revealDelay: Double?
    var revealAnimationTime: Double?

    var usesRecommendedSettings: Bool {
        isAutoHideEnabled
            && isZero(revealDelay)
            && isZero(revealAnimationTime)
    }

    var summary: String {
        if usesRecommendedSettings {
            return "Dock timing is optimized for DockDock."
        }

        return issues.joined(separator: " ")
    }

    var issues: [String] {
        var issues = [String]()

        if !isAutoHideEnabled {
            issues.append("Dock auto-hide is off.")
        }

        if !isZero(revealDelay) {
            issues.append("Reveal delay is \(formatted(revealDelay)).")
        }

        if !isZero(revealAnimationTime) {
            issues.append("Reveal animation time is \(formatted(revealAnimationTime)).")
        }

        return issues
    }

    private func isZero(_ value: Double?) -> Bool {
        guard let value else {
            return false
        }

        return abs(value) < 0.0001
    }

    private func formatted(_ value: Double?) -> String {
        guard let value else {
            return "not set"
        }

        return "\(String(format: "%.2f", value))s"
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
