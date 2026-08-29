#!/usr/bin/env bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
MONITOR="eDP-1"
RGB_SCRIPT="/opt/turbo-fan/facer_rgb.py"

# ==============================================================================
# STATE FUNCTIONS
# ==============================================================================

# Helper to check AC state via fast sysfs, falling back to upower
is_on_ac() {
    if compgen -G "/sys/class/power_supply/A*/online" >/dev/null; then
        grep -q "1" /sys/class/power_supply/A*/online 2>/dev/null
    else
        upower -i "$(upower -e | grep 'line_power' | head -n1)" | grep -q "online: *yes"
    fi
}

set_ac_profile() {
    # 1. Switch display to 144Hz
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })'

    # 2. Set power profile
    powerprofilesctl set performance

    # 3. Turn keyboard backlight to White @ 100%
    if [[ -x "$RGB_SCRIPT" ]]; then
        "$RGB_SCRIPT" -m 6 -cR 255 -cG 255 -cB 255 -b 100 >/dev/null 2>&1
    fi
}

set_bat_profile() {
    # 1. Switch display to 60Hz
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })'

    # 2. Set power profile
    powerprofilesctl set power-saver

    # 3. Turn keyboard backlight off (0%)
    if [[ -x "$RGB_SCRIPT" ]]; then
        "$RGB_SCRIPT" -b 0 >/dev/null 2>&1
    fi
}

apply_power_state() {
    if is_on_ac; then
        CURRENT_STATE="AC"
        set_ac_profile
    else
        CURRENT_STATE="BAT"
        set_bat_profile
    fi
}

# ==============================================================================
# MAIN EVENT LOOP
# ==============================================================================

# 1. Initial execution on boot/wake
apply_power_state
LAST_STATE="$CURRENT_STATE"

# 2. Event listener daemon
upower --monitor | while read -r line; do
    if [[ "$line" == *"line_power"* ]]; then
        if is_on_ac; then
            CURRENT_STATE="AC"
        else
            CURRENT_STATE="BAT"
        fi

        # Only trigger changes on actual state transitions
        if [[ "$CURRENT_STATE" != "$LAST_STATE" ]]; then
            if [[ "$CURRENT_STATE" == "AC" ]]; then
                set_ac_profile
            else
                set_bat_profile
            fi
            LAST_STATE="$CURRENT_STATE"
        fi
    fi
done
