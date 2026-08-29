#!/usr/bin/env python3
import time
import subprocess
import pathlib

def get_device_name(entry_path):
    """Reads device metadata only when a new device appears."""
    try:
        product_file = entry_path / "product"
        if not product_file.exists():
            return None
        name = product_file.read_text().strip()
        if not name or "root hub" in name.lower():
            return None
        
        manuf_file = entry_path / "manufacturer"
        if manuf_file.exists():
            manuf = manuf_file.read_text().strip()
            if manuf and manuf.lower() not in name.lower():
                name = f"{manuf} {name}"
        return name
    except Exception:
        return None

def send_notification(title, name, icon):
    subprocess.Popen(
        ["notify-send", "-a", "Device Manager", "-i", icon, title, name],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

def main():
    sys_usb = pathlib.Path("/sys/bus/usb/devices")
    if not sys_usb.exists():
        return

    # Cache mapping device ID (e.g., '1-4') to its resolved name
    known_devices = {}
    
    # Initial baseline scan on startup
    for entry in sys_usb.iterdir():
        if ":" in entry.name or "." in entry.name:
            continue
        name = get_device_name(entry)
        if name:
            known_devices[entry.name] = name

    while True:
        time.sleep(1) # Runs at 0% CPU footprint

        if not sys_usb.exists():
            continue

        # Get current active device IDs and their paths
        current_ids = set()
        current_entries = {}
        for entry in sys_usb.iterdir():
            if ":" in entry.name or "." in entry.name:
                continue
            current_ids.add(entry.name)
            current_entries[entry.name] = entry

        known_ids = set(known_devices.keys())

        # Quick check: if the device set hasn't changed, skip all processing
        added = current_ids - known_ids
        removed = known_ids - current_ids
        if not added and not removed:
            continue

        # Handle removals first
        for dev_id in removed:
            name = known_devices.pop(dev_id, None)
            if name:
                send_notification("Device Disconnected", name, "media-eject")

        # Handle additions
        for dev_id in added:
            entry = current_entries[dev_id]
            name = get_device_name(entry)
            if name:
                known_devices[dev_id] = name
                send_notification("Device Connected", name, "drive-removable-media")

if __name__ == '__main__':
    main()
