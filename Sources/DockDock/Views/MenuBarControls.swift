import AppKit
import DockDockCore
import SwiftUI

struct MenuBarControls: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var settings: AppSettings
    @ObservedObject var service: DockTriggerService
    @ObservedObject var overlay: TriggerBandOverlayService
    @ObservedObject var launchAtLogin: LaunchAtLoginService
    @State private var isEditingTriggerBand = false
    @State private var frontmostMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Enabled", isOn: $settings.isEnabled)
            Toggle("Sound", isOn: $settings.isSnapSoundEnabled)

            Divider()

            HStack {
                Text("Band")
                Spacer()
                Text("\(Int(settings.activationBand)) px")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .frame(width: 190)

            TriggerBandSlider(
                value: $settings.activationBand,
                width: 190,
                showsLabels: false,
                onEditingChanged: handleTriggerBandEditing
            )

            Picker("Edge", selection: $settings.dockEdge) {
                ForEach(DockEdge.allCases) { edge in
                    Text(edge.title).tag(edge)
                }
            }

            Divider()

            if let activeExclusionDescription = service.activeExclusionDescription {
                Text(activeExclusionDescription)
                    .foregroundStyle(.secondary)
            } else {
                Text(service.isRunning ? "Running" : "Stopped")
                    .foregroundStyle(service.isRunning ? .green : .secondary)
            }

            Button("Add Frontmost to Exceptions") {
                addFrontmostApp()
            }

            if let frontmostMessage {
                Text(frontmostMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Settings") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .onChange(of: settings.isEnabled) { service.restart() }
        .onChange(of: settings.activationBand) {
            if isEditingTriggerBand {
                overlay.show(settings: settings, autoHideAfter: nil)
            }
        }
        .onChange(of: settings.dockEdge) {
            overlay.show(settings: settings)
        }
    }

    private func handleTriggerBandEditing(_ isEditing: Bool) {
        isEditingTriggerBand = isEditing
        if isEditing {
            overlay.show(settings: settings, autoHideAfter: nil)
        } else {
            overlay.show(settings: settings)
        }
    }

    private func addFrontmostApp() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier,
              bundleID != Bundle.main.bundleIdentifier else {
            showFrontmostMessage("No frontmost app to add.")
            return
        }

        if settings.excludedBundleIDs.contains(bundleID) {
            showFrontmostMessage("\(app.localizedName ?? bundleID) is already excluded.")
            return
        }

        settings.addExcludedBundleID(bundleID)
        showFrontmostMessage("Added \(app.localizedName ?? bundleID) to exceptions.")
    }

    private func showFrontmostMessage(_ message: String) {
        frontmostMessage = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            if frontmostMessage == message {
                frontmostMessage = nil
            }
        }
    }
}
