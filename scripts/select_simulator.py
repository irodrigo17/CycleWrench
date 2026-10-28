#!/usr/bin/env python3
"""Choose an available iPhone simulator without pinning a runner's device name."""
import json
import re
import subprocess
import sys


def select_device(devices):
    candidates = []
    for runtime, entries in devices.items():
        match = re.search(r"\.iOS-(\d+(?:-\d+)*)$", runtime)
        if not match:
            continue
        version = tuple(int(part) for part in match.group(1).split("-"))
        for device in entries:
            if device.get("isAvailable") and device.get("name", "").startswith("iPhone"):
                candidates.append((version, device["name"], device["udid"]))
    if not candidates:
        raise ValueError("No available iPhone simulator. Install an iOS simulator runtime in Xcode.")
    return max(candidates)[2]


if __name__ == "__main__":
    try:
        data = json.loads(subprocess.check_output(
            ["xcrun", "simctl", "list", "devices", "available", "--json"], text=True))
        print(select_device(data["devices"]))
    except (subprocess.CalledProcessError, ValueError, KeyError) as error:
        sys.exit(str(error))
