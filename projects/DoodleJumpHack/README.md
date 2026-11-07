# Doodle Jump Hack v.1.26 😎

A separate MobileSubstrate tweak for the original Doodle Jump 1.26 app.

- Target bundle: `com.yourcompany.DoodleJump`
- Target app version: `1.26`
- Target architecture: `armv7` (iPhone 4S)
- Minimum firmware: iOS 6.0
- Feature: refills the type-0 power-up's fuel after its update method reaches zero, without modifying other power-up types.
- Package ID: `com.m3gaios6p0w3r.doodlejumphack`

## Reverse-engineering notes

The supplied original ARMv7 executable was inspected locally. Its Objective-C metadata includes `PowerUpObject`, `objType`, `objFuel`, `setObjFuel:`, and `tick`. In the initializer, type 0 receives an initial fuel value of 180. The `tick` method reads the fuel ivar directly, so the tweak hooks `tick` instead of the fuel getter. After the original tick completes, it restores the fuel to 180 only when the object's type is 0 and the fuel has reached zero or below.

Static code inspection supports the type-0 fuel behavior, but matching type 0 to the jetpack and confirming the exact runtime result still require testing in Doodle Jump 1.26. Do not install this development build on the primary phone until it has been reviewed and a safe test plan is agreed.

The original Doodle Jump executable and app resources are not modified or included in this package. The tweak is separately installed and is filtered to the Doodle Jump bundle identifier.
