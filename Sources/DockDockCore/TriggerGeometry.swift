import CoreGraphics

public struct TriggerGeometry: Equatable {
    public var activationBand: CGFloat
    public var edgeInset: CGFloat = 1

    public init(activationBand: CGFloat, edgeInset: CGFloat = 1) {
        self.activationBand = activationBand
        self.edgeInset = edgeInset
    }

    public func isInActivationBand(_ point: CGPoint, in displayBounds: CGRect, edge: DockEdge) -> Bool {
        guard activationBand > 0, displayBounds.contains(point) else {
            return false
        }

        switch edge {
        case .bottom:
            return point.y >= displayBounds.maxY - activationBand
        case .left:
            return point.x <= displayBounds.minX + activationBand
        case .right:
            return point.x >= displayBounds.maxX - activationBand
        }
    }

    public func shouldSnap(from previousPoint: CGPoint?, to point: CGPoint, in displayBounds: CGRect, edge: DockEdge) -> Bool {
        guard let previousPoint,
              isInActivationBand(point, in: displayBounds, edge: edge),
              !isInActivationBand(previousPoint, in: displayBounds, edge: edge) else {
            return false
        }

        switch edge {
        case .bottom:
            return point.y > previousPoint.y
        case .left:
            return point.x < previousPoint.x
        case .right:
            return point.x > previousPoint.x
        }
    }

    public func rearmDistance(dockClearance: CGFloat, extraMargin: CGFloat = 16) -> CGFloat {
        max(activationBand, dockClearance + extraMargin)
    }

    public func isBeyondRearmDistance(
        _ point: CGPoint,
        in displayBounds: CGRect,
        edge: DockEdge,
        rearmDistance: CGFloat
    ) -> Bool {
        guard rearmDistance > 0, displayBounds.contains(point) else {
            return false
        }

        switch edge {
        case .bottom:
            return point.y <= displayBounds.maxY - rearmDistance
        case .left:
            return point.x >= displayBounds.minX + rearmDistance
        case .right:
            return point.x <= displayBounds.maxX - rearmDistance
        }
    }

    public func snapPoint(for point: CGPoint, in displayBounds: CGRect, edge: DockEdge) -> CGPoint? {
        guard activationBand > 0, displayBounds.contains(point) else {
            return nil
        }

        switch edge {
        case .bottom:
            let triggerStart = displayBounds.maxY - activationBand
            let dockPixel = displayBounds.maxY - edgeInset
            guard point.y >= triggerStart, point.y < dockPixel else {
                return nil
            }
            return CGPoint(x: point.x, y: dockPixel)

        case .left:
            let dockPixel = displayBounds.minX + edgeInset
            guard point.x <= displayBounds.minX + activationBand, point.x > dockPixel else {
                return nil
            }
            return CGPoint(x: dockPixel, y: point.y)

        case .right:
            let triggerStart = displayBounds.maxX - activationBand
            let dockPixel = displayBounds.maxX - edgeInset
            guard point.x >= triggerStart, point.x < dockPixel else {
                return nil
            }
            return CGPoint(x: dockPixel, y: point.y)
        }
    }
}
