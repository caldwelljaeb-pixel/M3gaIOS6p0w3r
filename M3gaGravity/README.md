# M3gaGravity

A from-scratch SpringBoard gravity tweak for jailbroken iOS 6 devices.

## Target
- iPhone 4S / ARMv7
- iOS 6.1.3 (deployment target iOS 6.0)
- SpringBoard / MobileSubstrate
- Theos with the iOS 9.3 SDK, retaining 32-bit ARM compiler support

## V1 behavior
- Tilt-controlled acceleration from UIAccelerometer.
- Neutral-angle calibration when gravity is enabled, so the phone's resting angle is not treated as a constant tilt.
- Damped icon movement.
- Bounce against the bounds of each icon's parent view.
- Basic circle-style collision response between icons sharing the same parent view.
- Settings switch to enable/disable the effect (OFF by default).
- Disabling gravity restores each tracked icon view's original transform.

## Settings bundle
The PreferenceLoader entry registers `M3gaGravityPrefs` in Settings. Its `Resources/Info.plist` and `Resources/Root.plist` are staged into the preference bundle by Theos. The switch uses the `com.m3ga.m3gagravity` defaults domain.

## Safety defaults
Gravity is OFF by default. Enable it in Settings > M3gaGravity. Turn it off there to restore tracked icons. If SpringBoard becomes unstable, use substrate safe mode or remove the package rather than repeatedly respringing.

## Build

The current CI build suppresses the SDK deprecation warning for UIKit's legacy accelerometer API; that API is retained deliberately for iOS 6 runtime compatibility.

The GitHub Actions workflow builds an ARMv7 Debian package using Theos and uploads the .deb as a workflow artifact. It verifies the package metadata and file layout before uploading.

## Prototype limitations
This is a first physics prototype, not yet device-validated. Collisions only resolve for icons sharing the same immediate superview, so collisions across pages/dock containers are not implemented. Sensor direction and motion strength need physical testing on iOS 6.1.3. Icon view class and SpringBoard layout interactions also need on-device verification. The build must be confirmed successful before installing.
