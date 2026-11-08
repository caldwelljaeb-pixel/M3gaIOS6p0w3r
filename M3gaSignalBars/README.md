# M3gaSignalBars 0.1.1

An iOS 6.0–6.1.3 / ARMv7 SpringBoard tweak, intended for the iPhone 4S.

## Features

- Five full native iOS 6 cellular signal bars when enabled.
- Enable Fake Cell Bars switch in Settings, OFF by default.
- Switch OFF restores the latest real signal-bar count supplied by iOS.
- About the Tweak, Instructions, Info About Me, and Website entries.
- Creator credit: Made with ❤️ by M3gaIOS6p0w3r.

## Important

Cosmetic only. It does not improve reception, change the modem, unlock a carrier, or create cellular coverage, calls, SMS, or mobile data.

## iOS 6 implementation note

The iOS 6.1 UIKit runtime header for UIStatusBarSignalStrengthItemView exposes the signal count as the _signalStrengthBars ivar and updates it in updateForNewData:actions:. This version hooks that iOS 6 method, rather than a setter that is not present in the iOS 6.1 class interface.

## Test status

The source builds for ARMv7 and package verification checks the binary format, PreferenceLoader bundle registration, all Settings pages, the default-OFF switch, and package paths. Final visual behavior must still be tested on the physical device.

Made with ❤️ by M3gaIOS6p0w3r.
