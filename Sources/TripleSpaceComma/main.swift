import ApplicationServices
import Darwin
import Foundation
import TripleSpaceCommaCore

private enum Constants {
    static let deleteKeyCode: CGKeyCode = 51
    static let syntheticEventMarker: Int64 = 0x545343
    static let replacementDelay = DispatchTimeInterval.milliseconds(35)
    static let permissionRetryInterval: TimeInterval = 5
}

private func log(_ message: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    fputs("[\(timestamp)] \(message)\n", stderr)
}

private func markedEvent(_ event: CGEvent) -> CGEvent {
    event.setIntegerValueField(
        .eventSourceUserData,
        value: Constants.syntheticEventMarker
    )
    return event
}

private func postKey(_ keyCode: CGKeyCode, keyDown: Bool) {
    guard let event = CGEvent(
        keyboardEventSource: nil,
        virtualKey: keyCode,
        keyDown: keyDown
    ) else {
        return
    }

    markedEvent(event).post(tap: .cghidEventTap)
}

private func postDelete() {
    postKey(Constants.deleteKeyCode, keyDown: true)
    postKey(Constants.deleteKeyCode, keyDown: false)
}

private func postText(_ text: String) {
    for scalar in text.utf16 {
        guard let down = CGEvent(
            keyboardEventSource: nil,
            virtualKey: 0,
            keyDown: true
        ), let up = CGEvent(
            keyboardEventSource: nil,
            virtualKey: 0,
            keyDown: false
        ) else {
            continue
        }

        var character = scalar
        down.keyboardSetUnicodeString(stringLength: 1, unicodeString: &character)
        up.keyboardSetUnicodeString(stringLength: 1, unicodeString: &character)
        markedEvent(down).post(tap: .cghidEventTap)
        markedEvent(up).post(tap: .cghidEventTap)
    }
}

private func replacePreviousSpacingWithComma() {
    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.replacementDelay) {
        // This handles both native macOS double-space period replacement and two literal spaces.
        postDelete()
        postDelete()
        postText(", ")
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let controller = Unmanaged<EventTapController>
        .fromOpaque(userInfo)
        .takeUnretainedValue()
    return controller.handle(type: type, event: event)
}

private final class EventTapController {
    private var detector = SpaceTapDetector()
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        if event.getIntegerValueField(.eventSourceUserData) == Constants.syntheticEventMarker {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let isAutoRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        let timestamp = TimeInterval(event.timestamp) / 1_000_000_000

        guard detector.register(
            keyCode: keyCode,
            isAutoRepeat: isAutoRepeat,
            timestamp: timestamp
        ) else {
            return Unmanaged.passUnretained(event)
        }

        replacePreviousSpacingWithComma()
        return nil
    }

    func run() -> Never {
        requestAccessibilityPermission()

        var attempts = 0
        while !startEventTap() {
            if attempts == 0 || attempts % 12 == 0 {
                log("Waiting for Accessibility permission.")
            }
            attempts += 1
            Thread.sleep(forTimeInterval: Constants.permissionRetryInterval)
        }

        log("Triple Space Comma is running.")
        CFRunLoopRun()
        fatalError("The main run loop exited unexpectedly.")
    }

    private func requestAccessibilityPermission() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private func startEventTap() -> Bool {
        let mask = CGEventMask(1) << CGEventType.keyDown.rawValue
        let context = Unmanaged.passUnretained(self).toOpaque()

        tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: context
        )

        guard let tap else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }
}

private func runSelfTest() -> Bool {
    var detector = SpaceTapDetector(maximumInterval: 0.7)
    let first = detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.0)
    let second = detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.2)
    let third = detector.register(keyCode: 49, isAutoRepeat: false, timestamp: 1.4)
    let reset = detector.register(keyCode: 0, isAutoRepeat: false, timestamp: 1.5)
    return !first && !second && third && !reset
}

let arguments = Set(CommandLine.arguments.dropFirst())

if arguments.contains("--version") {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    print(version ?? "development")
    exit(EXIT_SUCCESS)
}

if arguments.contains("--self-test") {
    guard runSelfTest() else {
        fputs("SELF_TEST_FAIL\n", stderr)
        exit(EXIT_FAILURE)
    }
    print("SELF_TEST_PASS")
    exit(EXIT_SUCCESS)
}

EventTapController().run()
