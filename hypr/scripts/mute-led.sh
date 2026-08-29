#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# STEP 1: Create the Firmware Patch
# ------------------------------------------------------------------------------
# Initializes GPIO 2 Mask (0x716) and Direction (0x717) on node 0x01 at boot.
# (Note: Check Vendor/Subsystem IDs in `/proc/asound/card0/codec#0` if changed)

# sudo mkdir -p /lib/firmware
# sudo bash -c 'cat << "EOF" > /lib/firmware/alc-mute-led.fw
# [codec]
# 0x10ec0295 0x10251534 0
#
# [verb]
# 0x01 0x716 0x04
# 0x01 0x717 0x04
# EOF'

# ------------------------------------------------------------------------------
# STEP 2: Configure Modprobe & Rebuild Initramfs
# ------------------------------------------------------------------------------
# Instruct `snd-hda-intel` driver to load the firmware patch during early boot.

# echo "options snd-hda-intel patch=alc-mute-led.fw" | sudo tee /etc/modprobe.d/hda-mute-led.conf

# Rebuild early-boot initramfs (Choose command based on distro):
# Arch Only:  sudo mkinitcpio -P

# ------------------------------------------------------------------------------
# STEP 3: Grant Hardware Privileges to hda-verb
# ------------------------------------------------------------------------------
# Set SetUID bit so `hda-verb` can control /dev/snd/hwC0D0 without sudo.

# sudo chmod u+s $(which hda-verb)

# ------------------------------------------------------------------------------
# STEP 4: Load via hyprland.lua
# ------------------------------------------------------------------------------
# Listens to PipeWire/PulseAudio & DBus wake events to toggle GPIO 2 dynamically.

CODEC_DEV="/dev/snd/hwC0D0"

update_led() {
    # Re-assert GPIO 2 Mask (0x716) & Direction (0x717) in case codec power-cycled
    hda-verb "$CODEC_DEV" 0x01 0x716 0x04 >/dev/null 2>&1
    hda-verb "$CODEC_DEV" 0x01 0x717 0x04 >/dev/null 2>&1

    # Fetch mute status without subshell pipeline overhead
    local mute_info
    mute_info=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)

    if [[ "$mute_info" == *"yes"* ]]; then
        hda-verb "$CODEC_DEV" 0x01 0x715 0x04 >/dev/null 2>&1
    else
        hda-verb "$CODEC_DEV" 0x01 0x715 0x00 >/dev/null 2>&1
    fi
}

# Initial sync on boot/login
update_led

# 1. Background System Wake Listener (Catches Sleep -> Resume)
dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" 2>/dev/null | while read -r line; do
    case "$line" in
        *"boolean false"*)
            # Sound card needs ~1s to power back up after resume
            sleep 1
            update_led
            ;;
    esac
done &
DBUS_PID=$!

# Kill background dbus listener on script exit
trap 'kill "$DBUS_PID" 2>/dev/null' EXIT

# 2. Main Event Listener (Pure bash string matching, zero process-forking overhead)
pactl subscribe 2>/dev/null | while read -r event; do
    case "$event" in
        *"'change' on sink"*)
            update_led
            ;;
    esac
done
