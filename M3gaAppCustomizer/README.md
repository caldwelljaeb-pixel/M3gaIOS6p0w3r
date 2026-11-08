# M3gaAppCustomizer 0.1.6

A classic iOS app-name and app-image customization tweak for jailbroken iOS 6 devices.

- **Names** lists installed applications found in the iOS 6 app bundle locations. Each row has a text field for a replacement Home Screen label. Clearing the field restores the default name. Each app also has a native **Reset** button that removes its custom name and photo together.
- **Image Changing** lists the same installed apps. Tap one to open the Photos library and choose a replacement icon image. The chosen picture is scaled to fit inside the square icon with a small transparent margin, saved as a 2x Retina PNG, and loaded with its correct display scale.
- Includes Instructions, Info About Me, a Website button, and the creator credit.

The Settings bundle scans built-in app bundles in `/Applications` and downloaded app bundles in `/var/mobile/Applications/<UUID>/`. It reads each app's Info.plist for its bundle identifier and display name.

Preferences are stored in `/var/mobile/Library/Preferences/com.m3ga.appcustomizer.plist`.
Custom PNG files are stored in `/var/mobile/Library/M3gaAppCustomizer/Icons/<bundle-id>.png`.

App Customizer uses uniquely prefixed Settings controller classes to avoid collisions with other tweaks. The Reset button asks for confirmation, removes the app's saved name and custom PNG, and notifies SpringBoard to refresh. This is a test build. The package must be tested on an actual iOS 6 device before runtime behavior is considered verified. The build workflow does not publish to the main Cydia repository.
