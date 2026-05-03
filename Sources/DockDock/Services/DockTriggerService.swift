import ApplicationServices
import AppKit
import CoreGraphics
import DockDockCore
import Foundation

@MainActor
final class DockTriggerService: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var lastError: String?
    @Published private(set) var lastSnapDescription = "No snaps yet"
    @Published private(set) var activeExclusionDescription: String?
    @Published private(set) var hasAccessibilityPermission = AccessibilityPermission.isTrusted

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private weak var settings: AppSettings?
    private var lastSnapTime: CFAbsoluteTime = 0
    private var lastPointerLocation: CGPoint?
    private var isSnapArmed = true
    private var permissionTimer: Timer?

    func bind(settings: AppSettings) {
        self.settings = settings
        startPermissionMonitor()
        restart()
    }

    deinit {
        permissionTimer?.invalidate()
    }

    func restart() {
        stop()

        guard let settings, settings.isEnabled else {
            lastError = nil
            return
        }

        refreshPermission()
        guard hasAccessibilityPermission else {
            lastError = "Accessibility permission is required before DockDock can monitor mouse movement."
            return
        }

        let mask = CGEventMask(1 << CGEventType.mouseMoved.rawValue)
        let unmanagedSelf = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: DockTriggerService.eventCallback,
            userInfo: unmanagedSelf
        ) else {
            lastError = "Could not create the mouse event tap. Recheck Accessibility/Input Monitoring permission."
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
        lastError = nil
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        runLoopSource = nil
        eventTap = nil
        isRunning = false
        lastPointerLocation = nil
        isSnapArmed = true
    }

    func refreshPermission() {
        hasAccessibilityPermission = AccessibilityPermission.isTrusted
    }

    func requestPermission() {
        AccessibilityPermission.request()
        refreshPermission()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            refreshPermission()
            if hasAccessibilityPermission {
                restart()
            }
        }
    }

    private func startPermissionMonitor() {
        guard permissionTimer == nil else {
            return
        }

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollPermission()
            }
        }
    }

    private func pollPermission() {
        let wasTrusted = hasAccessibilityPermission
        refreshPermission()

        guard wasTrusted != hasAccessibilityPermission else {
            return
        }

        if hasAccessibilityPermission {
            restart()
        } else {
            stop()
            lastError = "Accessibility permission is required before DockDock can monitor mouse movement."
        }
    }

    private nonisolated static let eventCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard type == .mouseMoved, let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let service = Unmanaged<DockTriggerService>
            .fromOpaque(userInfo)
            .takeUnretainedValue()

        Task { @MainActor in
            service.handleMouseMoved(to: event.location)
        }

        return Unmanaged.passUnretained(event)
    }

    private func handleMouseMoved(to eventPoint: CGPoint) {
        let point = currentPointerLocation() ?? eventPoint

        guard let settings, settings.isEnabled else {
            lastPointerLocation = point
            return
        }

        if let excludedApp = frontmostExcludedApp(settings: settings) {
            activeExclusionDescription = "Paused for \(excludedApp)"
            lastPointerLocation = point
            return
        } else {
            activeExclusionDescription = nil
        }

        guard let displayBounds = DisplayGeometry.bounds(containing: point) else {
            lastPointerLocation = point
            return
        }

        let geometry = TriggerGeometry(activationBand: CGFloat(settings.activationBand))
        if !isSnapArmed {
            let dockClearance = DisplayGeometry.dockClearance(containing: point, edge: settings.dockEdge)
            let rearmDistance = geometry.rearmDistance(dockClearance: dockClearance)

            guard geometry.isBeyondRearmDistance(
                point,
                in: displayBounds,
                edge: settings.dockEdge,
                rearmDistance: rearmDistance
            ) else {
                lastPointerLocation = point
                return
            }

            isSnapArmed = true
        }

        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastSnapTime > 0.18 else {
            lastPointerLocation = point
            return
        }

        guard geometry.shouldSnap(
            from: lastPointerLocation,
            to: point,
            in: displayBounds,
            edge: settings.dockEdge
        ) else {
            lastPointerLocation = point
            return
        }

        guard let snapPoint = geometry.snapPoint(
            for: point,
            in: displayBounds,
            edge: settings.dockEdge
        ) else {
            lastPointerLocation = point
            return
        }

        lastSnapTime = now
        isSnapArmed = false
        CGWarpMouseCursorPosition(snapPoint)
        SnapSoundService.play()
        lastPointerLocation = snapPoint
        lastSnapDescription = "Snapped to \(Int(snapPoint.x)), \(Int(snapPoint.y))"
    }

    private func currentPointerLocation() -> CGPoint? {
        CGEvent(source: nil)?.location
    }

    private func frontmostExcludedApp(settings: AppSettings) -> String? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier,
              settings.excludedBundleIDs.contains(bundleID) else {
            return nil
        }

        return app.localizedName ?? bundleID
    }
}
