# M3gaGravity

A SpringBoard Home Screen physics tweak for jailbroken classic iOS devices.

## Target
- iOS 6.0 or later
- 32-bit ARM / ARMv7 devices, including iPhone 4 and iPhone 4S
- SpringBoard with MobileSubstrate and PreferenceLoader

## Interacting with icons
To interact with an app icon, **touch and hold the icon briefly, then move your finger**. Once picked up, keep moving your finger to drag the icon around the Home Screen. Release to fling it; the direction and speed of your movement affect the fling.

A quick horizontal swipe still changes Home Screen pages. The hold gesture is used to pick up an icon rather than starting a page swipe.

## Gravity and collisions
- Gravity is OFF by default. Turn it on in Settings > M3gaGravity when you are ready.
- Enabled icons fall automatically; the effect does not require tilting or shaking the iPhone.
- Icons can collide and form piles within their shared Home Screen icon container.
- Turn Gravity OFF to stop the simulation and restore tracked icons to their original positions.

## Settings
The M3gaGravity settings pane includes:
- An Enable Gravity switch, OFF by default
- Instructions for using the tweak
- An Info About Me page with the creator credit
- A Website button on the main settings page

The About Me and Instructions pages intentionally contain no website link.

## Performance and limitations
Physics updates are capped at approximately 30 updates per second to reduce the workload on older devices. Collision handling is limited to icons sharing the same immediate parent view; cross-container collisions are not implemented.

## Build
The ARMv7 Debian package is built with Theos using the iOS 9.3 SDK and an iOS 6.0 deployment target. GitHub Actions verifies the package layout, pane plists, preference controllers, Website selector, Gravity default, and creator credit.

## Device testing
The working preference pages, Website button, and hold-then-move icon interaction have been confirmed by the project maintainer on an iPhone 4S running iOS 6.1.3.

## Creator
**Made with ❤️ by M3gaIOS6p0w3r**
