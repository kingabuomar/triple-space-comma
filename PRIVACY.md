# Privacy

Triple Space Comma is deliberately local and content-free.

## What it observes

macOS gives the app system-wide key-down events after the user grants Accessibility permission. The app inspects only:

- the hardware key code;
- whether the event is an automatic repeat;
- the event timestamp; and
- an internal marker used to ignore the app's own synthetic events.

This is the minimum information needed to recognize three quick spacebar taps.

## What it never does

Triple Space Comma does not save, display, transmit, or log typed text. It does not keep a keystroke history. It has no analytics, advertising, user account, crash-reporting service, update service, or network code.

The lifecycle log records only timestamps and status messages such as “waiting for Accessibility permission” and “running.”

## Permission control

Accessibility access is controlled by macOS under **System Settings → Privacy & Security → Accessibility**. You can revoke it at any time. The bundled uninstaller also asks macOS to reset the app-specific Accessibility entry.

Because the complete source is included, the behavior can be independently inspected and built.
