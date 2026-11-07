# M3gaGravity

A from-scratch SpringBoard gravity tweak for jailbroken iOS 6 devices.

## Target
- iPhone 4S / ARMv7
- iOS 6.1.3 (deployment target iOS 6.0)
- SpringBoard / MobileSubstrate
- Theos, using the iOS 9.3 SDK for 32-bit ARM compilation

## V1 behavior
- Tilt-controlled acceleration from UIAccelerometer.
- Damped icon movement.
- Bounce against the bounds of each icon's parent view.
- Basic circle-style collision response between icons sharing the same parent view.
- Settings switch to enable/disable the effect.
- Disabling gravity restores each tracked icon view's original transform.

## Safety defaults
Gravity is OFF by default. Enable it in Settings > M3gaGravity. Turn it off there to restore tracked icons. If SpringBoard becomes unstable, use substrate safe mode or remove the package rather than repeatedly respringing.

## Build
The GitHub Actions workflow builds an ARMv7 Debian package using Theos and uploads the .deb as a workflow artifact.

## Prototype limitations
This is a first physics prototype, not yet device-validated. Collisions only resolve for icons sharing the same immediate superview, so collisions across pages/dock containers are not implemented. Sensor direction and motion strength need physical testing on iOS 6.1.3. Icon view class and layout interactions also need on-device verification.
