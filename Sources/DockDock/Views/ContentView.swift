import DockDockCore
import SwiftUI

struct ContentView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var service: DockTriggerService
    @ObservedObject var overlay: TriggerBandOverlayService
    @ObservedObject var launchAtLogin: LaunchAtLoginService
    @State private var isEditingTriggerBand = false
    @State private var isApplyingDockPreferences = false
    @State private var dockPreferencesMessage: DockPreferencesMessage?
    @State private var dockPreferencesStatus = DockPreferencesService.currentStatus()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            VStack(alignment: .leading, spacing: 16) {
                Toggle("Enable expanded Dock trigger zone", isOn: $settings.isEnabled)
                    .toggleStyle(.switch)

                Toggle("Play sound when DockDock snaps", isOn: $settings.isSnapSoundEnabled)
                    .toggleStyle(.switch)

                Toggle(
                    "Start DockDock when I log in",
                    isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.setEnabled($0) }
                    )
                )
                .toggleStyle(.switch)

                if let loginError = launchAtLogin.lastError {
                    Text(loginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Trigger band")
                        Spacer()
                        Text("\(Int(settings.activationBand)) px")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    TriggerBandSlider(
                        value: $settings.activationBand,
                        width: nil,
                        onEditingChanged: handleTriggerBandEditing
                    )
                }

                Picker("Dock edge", selection: $settings.dockEdge) {
                    ForEach(DockEdge.allCases) { edge in
                        Text(edge.title).tag(edge)
                    }
                }
                .pickerStyle(.segmented)
            }

            recommendedDockSettingsPanel

            ExclusionEditor(settings: settings)

            Divider()

            statusPanel

            Spacer()
        }
        .padding(28)
        .frame(width: 760, height: 740)
        .frame(minWidth: 720, minHeight: 700)
        .onChange(of: settings.isEnabled) { service.restart() }
        .onChange(of: settings.activationBand) {
            if isEditingTriggerBand {
                overlay.show(settings: settings, autoHideAfter: nil)
            }
        }
        .onChange(of: settings.dockEdge) {
            overlay.show(settings: settings)
        }
        .task {
            refreshDockPreferencesStatus()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DockDock")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("Open the auto-hidden Dock before the pointer reaches the last screen pixel.")
                .foregroundStyle(.secondary)
        }
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusBadge(
                    title: service.isRunning ? "Running" : "Stopped",
                    systemImage: service.isRunning ? "checkmark.circle.fill" : "pause.circle.fill",
                    tint: service.isRunning ? .green : .orange
                )

                Spacer()

                Text(service.lastSnapDescription)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if !service.hasAccessibilityPermission {
                permissionPanel
            } else if let error = service.lastError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
            } else if let activeExclusionDescription = service.activeExclusionDescription {
                Text(activeExclusionDescription)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text("Move into the configured edge band from outside the band. DockDock only snaps once on entry, so the pointer can move away normally.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var permissionPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Accessibility permission is required to monitor global mouse movement.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Button("Request Permission") {
                    service.requestPermission()
                }

                Button("Open System Settings") {
                    AccessibilityPermission.openSystemSettings()
                }

                Button("Recheck") {
                    service.refreshPermission()
                    service.restart()
                }
            }
        }
    }

    private var recommendedDockSettingsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(
                    dockPreferencesStatus.usesRecommendedSettings ? "Dock Settings Ready" : "Dock Settings Need Attention",
                    systemImage: dockPreferencesStatus.usesRecommendedSettings ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .font(.headline)
                .foregroundStyle(dockPreferencesStatus.usesRecommendedSettings ? .green : .orange)

                Spacer()

                Button("Recheck") {
                    refreshDockPreferencesStatus()
                }
                .controlSize(.small)
            }

            Text("For the fastest response, enable Dock auto-hide and remove the Dock's built-in reveal delay and animation time.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(dockPreferencesStatus.summary)
                .font(.caption)
                .foregroundStyle(dockPreferencesStatus.usesRecommendedSettings ? Color.secondary : Color.orange)

            HStack(spacing: 10) {
                Button {
                    applyRecommendedDockSettings()
                } label: {
                    if isApplyingDockPreferences {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Apply Recommended Dock Settings")
                    }
                }
                .disabled(isApplyingDockPreferences)

                Text("Restarts the Dock.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let dockPreferencesMessage {
                Text(dockPreferencesMessage.text)
                    .font(.caption)
                    .foregroundStyle(dockPreferencesMessage.isError ? .red : .green)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func handleTriggerBandEditing(_ isEditing: Bool) {
        isEditingTriggerBand = isEditing
        if isEditing {
            overlay.show(settings: settings, autoHideAfter: nil)
        } else {
            overlay.show(settings: settings)
        }
    }

    private func applyRecommendedDockSettings() {
        isApplyingDockPreferences = true
        dockPreferencesMessage = nil

        Task.detached {
            do {
                try DockPreferencesService.applyRecommendedAutohideSettings()
                await MainActor.run {
                    dockPreferencesMessage = DockPreferencesMessage(text: "Applied. The Dock has been restarted.", isError: false)
                    refreshDockPreferencesStatus()
                    isApplyingDockPreferences = false
                }
            } catch {
                await MainActor.run {
                    dockPreferencesMessage = DockPreferencesMessage(
                        text: error.localizedDescription,
                        isError: true
                    )
                    isApplyingDockPreferences = false
                }
            }
        }
    }

    private func refreshDockPreferencesStatus() {
        dockPreferencesStatus = DockPreferencesService.currentStatus()
    }
}

private struct DockPreferencesMessage {
    var text: String
    var isError: Bool
}
