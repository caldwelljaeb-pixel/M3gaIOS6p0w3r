# M3gaSignalBars

A small cosmetic jailbreak tweak for jailbroken iOS 6 ARMv7 devices.

## V1 features

- One Settings switch: **Enable Fake Cell Bars**
- When enabled, the native iOS cellular indicator is told to display five full bars.
- When disabled, the last real modem signal reading is restored.
- OFF by default.
- Only hooks SpringBoard's iOS 6 `SBTelephonyManager` signal-strength methods.
- Leaves carrier name, registration state, airplane mode, and data connection type untouched.
- Credits: **Made with ❤️ by M3gaIOS6p0w3r**

## Important

This is a status-bar appearance tweak, not a cellular network. It does not provide calls, SMS, mobile data, or coverage. If iOS hides the cellular indicator entirely because a SIM is missing or the system reports no service, the native UI may still suppress the bars; that behavior must be checked on the actual iPhone 4S.

## Package

- Package ID: `com.m3ga.m3gasignalbars`
- Version: `0.1.0`
- Architecture: `iphoneos-arm`
- Target: iOS 6.0+, ARMv7
- Preference domain: `com.m3ga.m3gasignalbars`

This is a development/test project. Builds are uploaded as GitHub Actions artifacts only. It is not automatically published to the live Cydia repository.
