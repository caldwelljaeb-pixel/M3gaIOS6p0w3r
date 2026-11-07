# TinyCarrier

A deliberately small MobileSubstrate tweak for classic iOS 6 devices.

- **Package ID:** `com.m3gaios6p0w3r.tinycarrier`
- **Version:** `0.1.0-1`
- **Target:** iOS 6.0+, armv7
- **What it does:** Replaces the carrier text in the status bar with `M3ga`.
- **Settings pane:** None; this first version is intentionally tiny.
- **Disable/remove:** Uninstall the package in Cydia.

## Implementation

Hooks the iOS 5/6 `SBStatusBarDataManager` selector
`_getServiceImageNames:directory:forOperator:statusBarCarrierName:`.
The method is referenced by the legacy Zeppelin implementation for iOS 5/6.

## Test status

This is an experimental first build. GitHub Actions builds a test .deb artifact only.
It is not automatically copied into the live Cydia repository and should not be installed
until the build succeeds and the hook is verified on the iPhone 4S running iOS 6.1.3.
