import AppKit
import CoreGraphics
import DockDockCore

enum DisplayGeometry {
    static func bounds(containing point: CGPoint) -> CGRect? {
        displayInfo(containing: point)?.bounds
    }

    static func dockClearance(containing point: CGPoint, edge: DockEdge) -> CGFloat {
        guard let info = displayInfo(containing: point),
              let screen = screen(for: info.displayID) else {
            return estimatedDockThickness()
        }

        let reservedThickness: CGFloat
        switch edge {
        case .bottom:
            reservedThickness = screen.visibleFrame.minY - screen.frame.minY
        case .left:
            reservedThickness = screen.visibleFrame.minX - screen.frame.minX
        case .right:
            reservedThickness = screen.frame.maxX - screen.visibleFrame.maxX
        }

        return max(reservedThickness, estimatedDockThickness())
    }

    private static func displayInfo(containing point: CGPoint) -> (displayID: CGDirectDisplayID, bounds: CGRect)? {
        var displayCount: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &displayCount) == .success, displayCount > 0 else {
            let mainDisplay = CGMainDisplayID()
            return (mainDisplay, CGDisplayBounds(mainDisplay))
        }

        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        guard CGGetActiveDisplayList(displayCount, &displays, &displayCount) == .success else {
            let mainDisplay = CGMainDisplayID()
            return (mainDisplay, CGDisplayBounds(mainDisplay))
        }

        for display in displays.prefix(Int(displayCount)) {
            let bounds = CGDisplayBounds(display)
            if bounds.contains(point) {
                return (display, bounds)
            }
        }

        let mainDisplay = CGMainDisplayID()
        return (mainDisplay, CGDisplayBounds(mainDisplay))
    }

    private static func screen(for displayID: CGDirectDisplayID) -> NSScreen? {
        NSScreen.screens.first { screen in
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }

            return screenNumber.uint32Value == displayID
        }
    }

    private static func estimatedDockThickness() -> CGFloat {
        let tileSize = UserDefaults(suiteName: "com.apple.dock")?
            .object(forKey: "tilesize") as? NSNumber
        let clampedTileSize = min(max(CGFloat(tileSize?.doubleValue ?? 64), 16), 128)
        return clampedTileSize + 36
    }
}
