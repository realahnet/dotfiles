#!/bin/bash
for ac in /sys/class/power_supply/AC* /sys/class/power_supply/ADP*; do
    if [ -f "$ac/online" ] && [ "$(cat "$ac/online")" -eq 1 ]; then
        exit 1 # On AC, so not on battery
    fi
done
exit 0 # On battery
