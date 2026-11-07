# M3gaIOS6p0w3r StatusBarColor

An iOS 6 jailbreak tweak project for selecting the RGB color used by status-bar item text and icons.

- Package ID: `com.m3gaios6p0w3r.statusbarcolor`
- Target: iOS 6.0+, armv7
- Settings: Enable switch and Red / Green / Blue numeric fields (0–255)
- Default color: Pale Lemon, RGB `255, 250, 168` (`#FFFAA8`)
- Credits: Made with ❤️ by M3gaIOS6p0w3r

## Important development note

The runtime hook currently prototypes the iOS 5/6 `UIStatusBarItemView -textColorForStyle:` method. This is a private API and must be verified on a real iOS 6 device before release. This source is a development build, not a release-ready package. Do not install until the build and runtime behavior have been tested.

The tweak and preference bundle are intentionally kept outside the live `debs/` repository until testing is complete.


CI builds use the Linux iOS cross-compilation toolchain and the iOS 9.3 SDK, with iOS 6.0 retained as the deployment target.
