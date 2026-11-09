#!/usr/bin/env python3
import plistlib
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

deb = Path(sys.argv[1])
if not deb.is_file():
    raise SystemExit("Debian package not found")

control = subprocess.check_output(["dpkg-deb", "-f", str(deb), "Package"], text=True).strip()
version = subprocess.check_output(["dpkg-deb", "-f", str(deb), "Version"], text=True).strip()
arch = subprocess.check_output(["dpkg-deb", "-f", str(deb), "Architecture"], text=True).strip()
assert (control, version, arch) == ("com.m3ga.appcustomizer", "0.1.7", "iphoneos-arm")

with tempfile.TemporaryDirectory() as temp:
    root = Path(temp)
    subprocess.check_call(["dpkg-deb", "-x", str(deb), str(root)])
    filter_path = root / "Library/MobileSubstrate/DynamicLibraries/M3gaAppCustomizer.plist"
    loader_path = root / "Library/PreferenceLoader/Preferences/M3gaAppCustomizer.plist"
    bundle = root / "Library/PreferenceBundles/M3gaAppCustomizerPrefs.bundle"
    dylib = root / "Library/MobileSubstrate/DynamicLibraries/M3gaAppCustomizer.dylib"
    source_expected = [
        bundle / "Root.plist",
        bundle / "Instructions.plist",
        bundle / "About.plist",
        bundle / "Info.plist",
        loader_path,
        filter_path,
        dylib,
    ]
    for path in source_expected:
        assert path.exists(), f"Missing package resource: {path.relative_to(root)}"

    with filter_path.open("rb") as f:
        filter_data = plistlib.load(f)
    assert "com.apple.springboard" in filter_data["Filter"]["Bundles"]

    with loader_path.open("rb") as f:
        loader = plistlib.load(f)
    entry = loader["entry"]
    assert entry["cell"] == "PSLinkCell"
    assert entry["bundle"] == "M3gaAppCustomizerPrefs"
    assert entry["detail"] == "M3GAAppCustomizerRootController"
    assert entry["isController"] is True

    with (bundle / "Root.plist").open("rb") as f:
        root_data = plistlib.load(f)
    root_text = repr(root_data)
    assert "Names" in root_text and "Image Changing" in root_text
    assert "Instructions" in root_text and "Info About Me" in root_text
    assert "openCreatorWebsite:" in root_text
    assert "Made with ❤️ by M3gaIOS6p0w3r" in root_text

    prefs_binary = bundle / "M3gaAppCustomizerPrefs"
    assert prefs_binary.exists()
    tweak_source = Path("M3gaAppCustomizer/Tweak.x").read_text(encoding="utf-8")
    assert "%hook SBApplicationIcon" in tweak_source, "App label and image-generation hooks must target SBApplicationIcon"
    assert "%hook SBIcon" in tweak_source and "- (id)getIconImage:(int)format" in tweak_source, "iOS 6.1 cached SBIcon image retrieval must also be overridden"
    assert "M3GACustomIconImageForIcon(self)" in tweak_source, "Both icon-rendering paths must use the shared custom image loader"
    assert "@selector(purgeCachedImages)" in tweak_source, "Icon changes must purge the iOS 6.1 SBIcon image cache"
    assert "M3gaAppCustomizer 0.1.7" in root_text, "Settings footer must show package version 0.1.7"
    assert "M3GAAppCustomizerNamesController" in root_text, "Names controller must be namespaced"
    assert "M3GAAppCustomizerImagesController" in root_text, "Image controller must be namespaced"

    prefs_source = Path("M3gaAppCustomizer/Preferences/M3GAppCustomizerPrefs.m").read_text(encoding="utf-8")
    assert 'cell:buttonCell edit:Nil];' in prefs_source and 'preferenceSpecifierNamed:@"Reset"' in prefs_source, "Each app row must use the native Reset button cell"
    assert 'M3GAAppCustomizerResetButtonCell' not in prefs_source, "Unsafe custom Reset cell must not be present"
    assert '[reset setButtonAction:@selector(resetAppCustomization:)]' in prefs_source, "Reset button must invoke its action"
    assert 'removeItemAtPath:iconPath' in prefs_source, "Reset must remove the saved custom image"
    assert 'CGFloat scale = MIN(' in prefs_source and 'CGFloat inset = 5.0' in prefs_source, "Selected photos must fit within the icon bounds"
    assert 'imageWithCGImage:storedImage.CGImage' in tweak_source and 'scale:imageScale' in tweak_source, "Saved PNGs must be reloaded with the correct Retina scale"
    for old_class in ('M3GRootController', 'M3GBaseController', 'M3GNamesController', 'M3GImagesController'):
        assert old_class not in prefs_source, f"Generic controller collision remains: {old_class}"

    data = (root / "Library/MobileSubstrate/DynamicLibraries/M3gaAppCustomizer.dylib").read_bytes()
    assert data[:4] in (b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe"), "Expected a little-endian Mach-O dylib"

print("M3gaAppCustomizer package metadata, ARMv7 binary, SpringBoard filter, Preferences bundle, loader entry, app-editing categories and creator pages verified.")
