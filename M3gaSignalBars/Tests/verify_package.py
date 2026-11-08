#!/usr/bin/env python3
import pathlib
import plistlib
import subprocess
import sys
import tempfile

deb = pathlib.Path(sys.argv[1])
def field(name):
    return subprocess.check_output(
        ["dpkg-deb", "-f", str(deb), name], text=True
    ).strip()

assert field("Package") == "com.m3ga.m3gasignalbars"
assert field("Version") == "0.1.0"
assert field("Architecture") == "iphoneos-arm"

with tempfile.TemporaryDirectory() as temp:
    root = pathlib.Path(temp)
    subprocess.check_call(["dpkg-deb", "-x", str(deb), str(root)])

    dylib = root / "Library/MobileSubstrate/DynamicLibraries/M3gaSignalBars.dylib"
    filter_plist = root / "Library/MobileSubstrate/DynamicLibraries/M3gaSignalBars.plist"
    prefs_bundle = root / "Library/PreferenceBundles/M3gaSignalBarsPrefs.bundle"
    loader_plist = root / "Library/PreferenceLoader/Preferences/M3gaSignalBars.plist"

    assert dylib.is_file() and dylib.stat().st_size > 1000, "Missing/empty tweak dylib"
    assert filter_plist.is_file(), "Missing SpringBoard filter"
    assert prefs_bundle.is_dir(), "Missing Settings bundle"
    assert (prefs_bundle / "Root.plist").is_file(), "Missing Settings root plist"
    assert (prefs_bundle / "Instructions.plist").is_file(), "Missing Instructions page"
    assert (prefs_bundle / "About.plist").is_file(), "Missing About page"
    assert loader_plist.is_file(), "Missing PreferenceLoader entry"

    with filter_plist.open("rb") as stream:
        target_filter = plistlib.load(stream)
    assert target_filter["Filter"]["Bundles"] == ["com.apple.springboard"]

    with (prefs_bundle / "Root.plist").open("rb") as stream:
        root_prefs = plistlib.load(stream)
    switch = next(item for item in root_prefs["items"]
                  if item.get("key") == "Enabled")
    assert switch["default"] is False, "Enable switch must default OFF"
    assert switch["PostNotification"] ==         "com.m3ga.m3gasignalbars/preferences.changed"

    with (prefs_bundle / "Info.plist").open("rb") as stream:
        info = plistlib.load(stream)
    assert info.get("CFBundleIdentifier") == "com.m3ga.m3gasignalbars.preferences"

    magic = dylib.read_bytes()[:4]
    assert magic in (b"\xce\xfa\xed\xfe", b"\xcf\xfa\xed\xfe"),         "Tweak is not a little-endian ARM Mach-O image"

print("M3gaSignalBars package structure, Settings, default-OFF preference, "
      "SpringBoard filter, and ARM Mach-O header verified.")
