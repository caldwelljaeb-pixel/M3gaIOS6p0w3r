#!/usr/bin/env python3
import plistlib
import subprocess
import sys
import tempfile
from pathlib import Path

def field(deb: str, name: str) -> str:
    return subprocess.check_output(["dpkg-deb", "-f", deb, name], text=True).strip()

def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: verify_package.py PACKAGE.deb")

    deb = sys.argv[1]
    assert field(deb, "Package") == "com.m3ga.m3gasignalbars"
    assert field(deb, "Version") == "0.1.0"
    assert field(deb, "Architecture") == "iphoneos-arm"

    with tempfile.TemporaryDirectory(prefix="m3gasignalbars-") as temp:
        root = Path(temp)
        subprocess.check_call(["dpkg-deb", "-x", deb, str(root)])

        dylib = root / "Library/MobileSubstrate/DynamicLibraries/M3gaSignalBars.dylib"
        filter_plist = root / "Library/MobileSubstrate/DynamicLibraries/M3gaSignalBars.plist"
        pref_bundle = root / "Library/PreferenceBundles/M3gaSignalBarsPrefs.bundle"
        entry = root / "Library/PreferenceLoader/Preferences/M3gaSignalBars.plist"

        for path in (dylib, filter_plist, pref_bundle / "Info.plist",
                     pref_bundle / "Root.plist", entry):
            assert path.is_file(), f"missing package file: {path}"

        with filter_plist.open("rb") as handle:
            filter_data = plistlib.load(handle)
        assert "com.apple.springboard" in filter_data["Filter"]["Bundles"]

        with (pref_bundle / "Info.plist").open("rb") as handle:
            info = plistlib.load(handle)
        assert info["NSPrincipalClass"] == "M3gaSignalBarsController"

        with (pref_bundle / "Root.plist").open("rb") as handle:
            specifiers = plistlib.load(handle)
        switch = next(item for item in specifiers if item.get("cell") == "PSSwitchCell")
        assert switch["key"] == "Enabled"
        assert switch["default"] is False
        assert switch["defaults"] == "com.m3ga.m3gasignalbars"

        entry_text = entry.read_text(encoding="utf-8")
        assert "M3gaSignalBarsPrefs" in entry_text
        assert "M3gaSignalBarsController" in entry_text

    print("M3gaSignalBars package contents and default-OFF preference checks passed.")

if __name__ == "__main__":
    main()
