#!/usr/bin/env python3
"""Verify the installed M3gaGravity 0.2.14 preference bundle inside a built Debian package."""

from __future__ import annotations

import plistlib
import subprocess
import sys
import tempfile
from pathlib import Path


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"Preference verification failed: {message}")


def load_plist(path: Path) -> dict:
    require(path.is_file(), f"missing plist: {path}")
    with path.open("rb") as handle:
        value = plistlib.load(handle)
    require(isinstance(value, dict), f"{path.name} must contain a plist dictionary")
    return value


def flatten_strings(value) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, dict):
        return sum((flatten_strings(v) for v in value.values()), [])
    if isinstance(value, list):
        return sum((flatten_strings(v) for v in value), [])
    return []


def main() -> None:
    require(len(sys.argv) == 2, "usage: verify_preferences.py PACKAGE.deb")
    deb = Path(sys.argv[1]).resolve()
    require(deb.is_file(), f"package not found: {deb}")

    with tempfile.TemporaryDirectory(prefix="m3gagravity-check-") as temporary:
        destination = Path(temporary)
        subprocess.run(
            ["dpkg-deb", "--extract", str(deb), str(destination)],
            check=True,
        )

        preferences_dir = destination / "Library/PreferenceLoader/Preferences"
        bundle = destination / "Library/PreferenceBundles/M3gaGravityPrefs.bundle"

        entry_file = preferences_dir / "M3gaGravity.plist"
        entry_plist = load_plist(entry_file)
        entry = entry_plist.get("entry", {})
        require(entry.get("bundle") == "M3gaGravityPrefs", "Settings entry must load M3gaGravityPrefs")
        require(entry.get("detail") == "M3GRootController", "Settings entry must target M3GRootController")
        require(entry.get("isController") is True, "main Settings entry must be marked as a controller")
        require(entry.get("overridePrincipalClass") is True, "main Settings entry must override its principal class")

        info = load_plist(bundle / "Info.plist")
        require(info.get("NSPrincipalClass") == "M3GRootController", "bundle principal class must be M3GRootController")
        require(info.get("MinimumOSVersion") == "6.0", "minimum iOS version must remain 6.0")
        require(info.get("CFBundleShortVersionString") == "0.2.14", "preference bundle version must be 0.2.14")

        panes = {}
        for name in ("Root", "Instructions", "About"):
            pane = load_plist(bundle / f"{name}.plist")
            items = pane.get("items")
            require(isinstance(items, list) and items, f"{name}.plist must contain non-empty items")
            panes[name] = (pane, items)

        root_items = panes["Root"][1]
        root_by_label = {
            item.get("label"): item for item in root_items if isinstance(item, dict)
        }
        switch = root_by_label.get("Enable Gravity")
        require(switch is not None, "main page must contain Enable Gravity")
        require(switch.get("cell") == "PSSwitchCell", "Enable Gravity must be a switch")
        require(switch.get("default") is False, "Gravity must be OFF by default")

        for label, controller in (
            ("Instructions", "M3GInstructionsController"),
            ("Info About Me", "M3GAboutController"),
        ):
            specifier = root_by_label.get(label)
            require(specifier is not None, f"main page must contain {label}")
            require(specifier.get("cell") == "PSLinkCell", f"{label} must be a link cell")
            require(specifier.get("detail") == controller, f"{label} must target {controller}")
            require(specifier.get("isController") is True, f"{label} must load its controller")
            require(specifier.get("overridePrincipalClass") is True, f"{label} must use its detail controller")

        website = root_by_label.get("Website")
        require(website is not None, "main page must contain a Website button")
        require(website.get("cell") == "PSButtonCell", "Website must be a button")
        require(website.get("action") == "openCreatorWebsite:", "Website button must call openCreatorWebsite:")

        instructions_text = "\n".join(flatten_strings(panes["Instructions"][0]))
        about_text = "\n".join(flatten_strings(panes["About"][0]))
        require("touch and hold" in instructions_text.lower(), "Instructions must include drag/pickup guidance")
        require("gravity is off by default" in instructions_text.lower(), "Instructions must explain default-off behavior")
        require("made with ❤️ by m3gaios6p0w3r" in about_text.lower(), "About page must include creator credit")
        for name, content in (("Instructions", instructions_text), ("About", about_text)):
            require("website" not in content.lower(), f"{name} page must not mention the website")
            require("github.com" not in content.lower(), f"{name} page must not contain a GitHub URL")
            require("http://" not in content.lower() and "https://" not in content.lower(),
                    f"{name} page must not contain a URL")

        binary = bundle / "M3gaGravityPrefs"
        require(binary.is_file(), "preference bundle executable is missing")
        symbols = subprocess.run(
            ["strings", str(binary)],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        for required_symbol in (
            "M3GRootController",
            "M3GInstructionsController",
            "M3GAboutController",
            "openCreatorWebsite:",
            "setSpecifiers:",
        ):
            require(required_symbol in symbols, f"preference binary is missing {required_symbol}")

        version = subprocess.run(
            ["dpkg-deb", "-f", str(deb), "Version"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        require(version == "0.2.14", f"expected Debian package version 0.2.14, got {version}")

    print("M3gaGravity 0.2.14 preference checks passed.")
    print("- Main pane controller and Website action are present.")
    print("- Root, Instructions, and About panes contain specifiers.")
    print("- Instructions/About have no website text or URLs.")
    print("- Gravity default is OFF and creator credit is present.")


if __name__ == "__main__":
    main()
