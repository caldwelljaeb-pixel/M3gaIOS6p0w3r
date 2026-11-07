# M3gaGravity

A from-scratch SpringBoard gravity tweak for jailbroken iOS 6 devices.

## Target
- iOS 6.1.3
- iPhone 4S / ARMv7
- SpringBoard
- Theos + MobileSubstrate

## V1 direction
Tilt-controlled physics: the accelerometer supplies gravity, icon views gain velocity and position offsets, and screen edges bounce icons back into the visible area.

## Current prototype status
The first source prototype hooks `SBIconView`, tracks icon views, reads `UIAccelerometer`, and applies damped motion with edge bounce. Sensor direction, SpringBoard class compatibility, icon layout interaction, and tap behavior must be verified on an iOS 6 device before this is considered installable.

## Planned next milestones
1. Build and inspect the ARMv7 package.
2. Verify icon discovery and tilt direction on-device.
3. Add icon-to-icon collision response.
4. Add shake-to-scatter and a safe restore/disable control.
5. Test repeated SpringBoard relaunches before publishing.
