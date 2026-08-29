import Darwin
import Foundation

@main
enum SpaceTapDetectorTests {
    private static var failures = 0

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            failures += 1
            fputs("FAIL: \(message)\n", stderr)
        }
    }

    private static func threeQuickSpacesTriggerOnce() {
        var detector = SpaceTapDetector(maximumInterval: 0.7)

        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.0), "first space must not trigger")
        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.2), "second space must not trigger")
        expect(detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.4), "third quick space must trigger")
        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.6), "detector must reset after a trigger")
    }

    private static func slowSpacesDoNotTrigger() {
        var detector = SpaceTapDetector(maximumInterval: 0.7)

        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.0), "first slow-space sample")
        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.8), "second slow-space sample")
        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 2.6), "slow spaces must never trigger")
    }

    private static func anotherKeyResetsTheSequence() {
        var detector = SpaceTapDetector()

        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.0), "first space before reset")
        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.1), "second space before reset")
        expect(!detector.register(keyCode: 0, isAutoRepeat: false, timestamp: 1.2), "non-space must not trigger")
        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.3), "space after reset is first")
    }

    private static func autoRepeatDoesNotCountAsASequence() {
        var detector = SpaceTapDetector()

        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.0), "first space before repeat")
        expect(!detector.register(keyCode: 49, isAutoRepeat: true, timestamp: 1.1), "repeat must reset")
        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.2), "first space after repeat")
        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.3), "second space after repeat")
    }

    private static func clockGoingBackwardsStartsANewSequence() {
        var detector = SpaceTapDetector()

        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 10.0), "initial clock sample")
        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 9.0), "backwards clock resets")
        expect(!detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 9.1), "second sample after reset")
    }

    static func main() {
        threeQuickSpacesTriggerOnce()
        slowSpacesDoNotTrigger()
        anotherKeyResetsTheSequence()
        autoRepeatDoesNotCountAsASequence()
        clockGoingBackwardsStartsANewSequence()

        if failures > 0 {
            fputs("CORE_TESTS_FAIL \(failures)\n", stderr)
            exit(EXIT_FAILURE)
        }

        print("CORE_TESTS_PASS")
    }
}
