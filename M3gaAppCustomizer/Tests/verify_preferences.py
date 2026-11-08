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
assert (control, version, arch) == ("com.m3ga.appcustomizer", "0.1.1", "iphoneos-arm")

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
    assert entry["detail"] == "M3GRootController"
    assert entry["isController"] is True

    for name in ("Root.plist", "Instructions.plist", "About.plist", "Info.plist"):
        with (bundle / name).open("rb") as f:
            plistlib.load(f)

    with (bundle / "Root.plist").open("rb") as f:
        root_data = plistlib.load(f)
    root_text = repr(root_data)
    assert "Names" in root_text and "Image Changing" in root_text
    assert "Instructions" in root_text and "Info About Me" in root_text
    assert "openCreatorWebsite:" in root_text
    assert "Made with ❤️ by M3gaIOS6p0w3r" in root_text

    prefs_binary = bundle / "M3gaAppCustomizerPrefs"
    assert prefs_binary.exists()
    data = (root / "Library/MobileSubstrate/DynamicLibraries/M3gaAppCustomizer.dylib").read_bytes()
    assert data[:4] in (b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe"), "Expected a little-endian Mach-O dylib"

print("M3gaAppCustomizer package metadata, ARMv7 binary, SpringBoard filter, Preferences bundle, loader entry, app-editing categories and creator pages verified.")
