# M3gaSignalBars 0.1.0

An iOS 6.1.3 / ARMv7 SpringBoard tweak for the iPhone 4S.

## What it does

When enabled, it asks the native iOS cellular signal view to display five full bars. It remembers the real bar value supplied by the system and restores that value when disabled.

This is entirely cosmetic. It does not improve reception or create cellular service, calls, SMS, or mobile data. If iOS is not showing a native cellular signal item (for example, no SIM/no service), the tweak cannot make that system item appear.

## Settings

Settings → M3gaSignalBars → Enable Fake Cell Bars

The switch defaults to OFF. Instructions, creator information, and a working creator website link are included.

## Build

Built using Theos for `iphone:clang:9.3:6.0`, `armv7`, with mobilesubstrate and preferenceloader dependencies.

## Test status

This is a first test build. Package metadata, installed paths, plist contents, default-OFF setting, and ARM Mach-O format are checked in GitHub Actions. Actual behavior still requires testing on an iPhone 4S running iOS 6.1.3.

Made with ❤️ by M3gaIOS6p0w3r.
