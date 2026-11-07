# Doodle Jump Hack v.1.26 😎

A separate MobileSubstrate tweak for the original Doodle Jump 1.26 app.

- Target bundle: `com.yourcompany.DoodleJump`
- Target app version: `1.26`
- Target architecture: `armv7` (iPhone 4S)
- Minimum firmware: iOS 6.0
- Feature: continuously refills the jetpack's fuel value, leaving other power-up types unchanged.
- Package ID: `com.m3gaios6p0w3r.doodlejumphack`

## Reverse-engineering notes

The supplied original ARMv7 executable was inspected locally. Its Objective-C metadata includes `PowerUpObject`, `objType`, `objFuel`, and `setObjFuel:`. In the collision handler, the type-0 power-up is created on the jetpack path. Its initial fuel is 180. The main game loop checks its fuel through the getter before expiring the active power-up.

The tweak hooks only `-[PowerUpObject objFuel]`. When the object is type 0 and its fuel reaches zero or below, the tweak restores the original 180-frame fuel value. Other power-up types are returned unchanged.

## Safety and validation

This is a development build, not a release. Static analysis identifies the relevant class, selectors, type value, and fuel threshold, but the hook still requires runtime testing in the exact Doodle Jump 1.26 build. Do not install it on the primary phone until a test build has been reviewed and a safe test plan is agreed.

The original Doodle Jump executable and app resources are not modified or included in this package. The tweak is separately installed and is filtered to the Doodle Jump bundle identifier.
