# M3gaSignalBars 0.1.3

An iOS 6.0–6.1.3 / ARMv7 tweak intended for the iPhone 4S.

## Features

- Five full native iOS 6 cellular signal bars when enabled.
- Enable Fake Cell Bars switch in Settings, OFF by default.
- Switch OFF restores the latest real modem signal-bar count.
- About the Tweak, Instructions, Info About Me, and Website entries.
- Creator credit: Made with ❤️ by M3gaIOS6p0w3r.

## Implementation changes

This build targets both SpringBoard and UIKit-linked apps. It hooks the iOS 6 UIStatusBarSignalStrengthItemView updateForNewData:actions: method and contentsImageForStyle: so native signal imagery is generated with five bars while enabled. The saved modem count is restored when disabled.

A small diagnostic log is written to /var/mobile/Documents/M3gaSignalBars-Debug.txt. It records which process loads the tweak, whether the iOS 6 signal class and hooks were found, and whether a signal view was discovered. This makes it possible to troubleshoot device-specific behavior without changing the Settings pages.

## Important

Cosmetic only. It does not improve reception, change the modem, unlock a carrier, or create cellular coverage, calls, SMS, or mobile data.

## Test status

The ARMv7 package and its metadata, injection filters, preference pages, and default-OFF setting are verified by the build workflow. Visual behavior still requires confirmation on the physical iPhone.

Made with ❤️ by M3gaIOS6p0w3r.
