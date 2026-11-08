# M3gaSignalBars 0.1.2

An iOS 6.0–6.1.3 / ARMv7 tweak intended for the iPhone 4S. The MobileSubstrate filter targets UIKit apps so the hook runs in the processes that render their native status bars.

## Features

- Five full native iOS 6 cellular signal bars when enabled.
- Enable Fake Cell Bars switch in Settings, OFF by default.
- Switch OFF restores the latest real signal-bar count supplied by iOS.
- About the Tweak, Instructions, Info About Me, and Website entries.
- Creator credit: Made with ❤️ by M3gaIOS6p0w3r.

## Important

Cosmetic only. It does not improve reception, change the modem, unlock a carrier, or create cellular coverage, calls, SMS, or mobile data.

## iOS 6 implementation note

The iOS 6.1 UIKit runtime interface for UIStatusBarSignalStrengthItemView exposes the signal count as the _signalStrengthBars ivar and updates it in updateForNewData:actions:. This version hooks that iOS 6 method, rather than a setter that is not present in the iOS 6.1 class interface.

The injection filter uses com.apple.UIKit rather than targeting SpringBoard alone. UIKit applications render their own status-bar views, so a SpringBoard-only filter can miss the views that need the change.

## Test status

The source builds for ARMv7 and package verification checks the binary format, UIKit injection filter, PreferenceLoader bundle registration, all Settings pages, the default-OFF switch, and package paths. Final visual behavior must still be tested on the physical device.

Made with ❤️ by M3gaIOS6p0w3r.
