import Foundation

/// A tiny, content-free state machine that recognizes three quick spacebar taps.
public struct SpaceTapDetector: Sendable {
    public static let spaceKeyCode: Int64 = 49

    public let maximumInterval: TimeInterval

    private var consecutiveSpaceTaps = 0
    private var lastSpaceTimestamp: TimeInterval?

    public init(maximumInterval: TimeInterval = 0.7) {
        precondition(maximumInterval > 0, "maximumInterval must be positive")
        self.maximumInterval = maximumInterval
    }

    /// Returns true only when the current key event completes a valid triple-space gesture.
    public mutating func register(
        keyCode: Int64,
        isAutoRepeat: Bool,
        timestamp: TimeInterval
    ) -> Bool {
        guard keyCode == Self.spaceKeyCode, !isAutoRepeat else {
            reset()
            return false
        }

        if let lastSpaceTimestamp,
           timestamp >= lastSpaceTimestamp,
           timestamp - lastSpaceTimestamp <= maximumInterval {
            consecutiveSpaceTaps += 1
        } else {
            consecutiveSpaceTaps = 1
        }

        lastSpaceTimestamp = timestamp

        guard consecutiveSpaceTaps == 3 else {
            return false
        }

        reset()
        return true
    }

    public mutating func reset() {
        consecutiveSpaceTaps = 0
        lastSpaceTimestamp = nil
    }
}
