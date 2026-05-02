import CoreGraphics
import DockDockCore
import Foundation

private let bounds = CGRect(x: 0, y: 0, width: 1440, height: 900)

private func expectEqual(_ actual: CGPoint?, _ expected: CGPoint, _ label: String) {
    guard actual == expected else {
        fatalError("\(label): expected \(expected), got \(String(describing: actual))")
    }
}

private func expectNil(_ actual: CGPoint?, _ label: String) {
    guard actual == nil else {
        fatalError("\(label): expected nil, got \(String(describing: actual))")
    }
}

private func expectTrue(_ actual: Bool, _ label: String) {
    guard actual else {
        fatalError("\(label): expected true")
    }
}

private func expectFalse(_ actual: Bool, _ label: String) {
    guard !actual else {
        fatalError("\(label): expected false")
    }
}

let bottom = TriggerGeometry(activationBand: 40)
expectEqual(
    bottom.snapPoint(for: CGPoint(x: 720, y: 870), in: bounds, edge: .bottom),
    CGPoint(x: 720, y: 899),
    "bottom edge snaps inside activation band"
)
expectNil(
    bottom.snapPoint(for: CGPoint(x: 720, y: 850), in: bounds, edge: .bottom),
    "bottom edge ignores outside activation band"
)
expectFalse(
    bottom.shouldSnap(from: CGPoint(x: 720, y: 899), to: CGPoint(x: 720, y: 880), in: bounds, edge: .bottom),
    "bottom edge does not resnap while leaving the dock edge"
)

expectTrue(
    bottom.shouldSnap(from: CGPoint(x: 720, y: 850), to: CGPoint(x: 720, y: 870), in: bounds, edge: .bottom),
    "bottom edge should snap only when entering the activation band"
)

let bottomRearmDistance = bottom.rearmDistance(dockClearance: 96)
expectFalse(
    bottom.isBeyondRearmDistance(
        CGPoint(x: 720, y: 810),
        in: bounds,
        edge: .bottom,
        rearmDistance: bottomRearmDistance
    ),
    "bottom edge stays disarmed while still near the Dock"
)
expectTrue(
    bottom.isBeyondRearmDistance(
        CGPoint(x: 720, y: 788),
        in: bounds,
        edge: .bottom,
        rearmDistance: bottomRearmDistance
    ),
    "bottom edge rearms after moving above the Dock clearance"
)

let side = TriggerGeometry(activationBand: 24)
expectEqual(
    side.snapPoint(for: CGPoint(x: 12, y: 300), in: bounds, edge: .left),
    CGPoint(x: 1, y: 300),
    "left edge snaps inside activation band"
)
expectEqual(
    side.snapPoint(for: CGPoint(x: 1428, y: 300), in: bounds, edge: .right),
    CGPoint(x: 1439, y: 300),
    "right edge snaps inside activation band"
)

let sideRearmDistance = side.rearmDistance(dockClearance: 80)
expectFalse(
    side.isBeyondRearmDistance(
        CGPoint(x: 86, y: 300),
        in: bounds,
        edge: .left,
        rearmDistance: sideRearmDistance
    ),
    "left edge stays disarmed while still near the Dock"
)
expectTrue(
    side.isBeyondRearmDistance(
        CGPoint(x: 100, y: 300),
        in: bounds,
        edge: .left,
        rearmDistance: sideRearmDistance
    ),
    "left edge rearms after moving beyond Dock clearance"
)

print("GeometryChecks passed")
