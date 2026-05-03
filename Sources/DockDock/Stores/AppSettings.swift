import Foundation
import DockDockCore

@MainActor
final class AppSettings: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }

    @Published var activationBand: Double {
        didSet { defaults.set(activationBand, forKey: Keys.activationBand) }
    }

    @Published var dockEdge: DockEdge {
        didSet { defaults.set(dockEdge.rawValue, forKey: Keys.dockEdge) }
    }

    @Published var isSnapSoundEnabled: Bool {
        didSet { defaults.set(isSnapSoundEnabled, forKey: Keys.isSnapSoundEnabled) }
    }

    @Published var showMenuBarExtra: Bool {
        didSet { defaults.set(showMenuBarExtra, forKey: Keys.showMenuBarExtra) }
    }

    @Published var excludedBundleIDs: [String] {
        didSet {
            defaults.set(excludedBundleIDs, forKey: Keys.excludedBundleIDs)
        }
    }

    @Published var hasAskedLaunchAtLogin: Bool {
        didSet {
            defaults.set(hasAskedLaunchAtLogin, forKey: Keys.hasAskedLaunchAtLogin)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        let savedBand = defaults.object(forKey: Keys.activationBand) as? Double ?? 15
        activationBand = min(max(savedBand, 1), 50)

        if let rawEdge = defaults.string(forKey: Keys.dockEdge),
           let edge = DockEdge(rawValue: rawEdge) {
            dockEdge = edge
        } else {
            dockEdge = .bottom
        }

        showMenuBarExtra = defaults.object(forKey: Keys.showMenuBarExtra) as? Bool ?? true
        isSnapSoundEnabled = defaults.object(forKey: Keys.isSnapSoundEnabled) as? Bool ?? true
        excludedBundleIDs = defaults.stringArray(forKey: Keys.excludedBundleIDs) ?? []
        hasAskedLaunchAtLogin = defaults.object(forKey: Keys.hasAskedLaunchAtLogin) as? Bool ?? false
    }

    func addExcludedBundleID(_ bundleID: String) {
        let trimmed = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !excludedBundleIDs.contains(trimmed) else {
            return
        }

        excludedBundleIDs.append(trimmed)
        excludedBundleIDs.sort()
    }

    func removeExcludedBundleID(_ bundleID: String) {
        excludedBundleIDs.removeAll { $0 == bundleID }
    }

    private enum Keys {
        static let isEnabled = "isEnabled"
        static let activationBand = "activationBand"
        static let dockEdge = "dockEdge"
        static let isSnapSoundEnabled = "isSnapSoundEnabled"
        static let showMenuBarExtra = "showMenuBarExtra"
        static let excludedBundleIDs = "excludedBundleIDs"
        static let hasAskedLaunchAtLogin = "hasAskedLaunchAtLogin"
    }
}
