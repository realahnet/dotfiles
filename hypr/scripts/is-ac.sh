#!/bin/bash
for ac in /sys/class/power_supply/AC* /sys/class/power_supply/ADP*; do
    if [ -f "$ac/online" ] && [ "$(cat "$ac/online")" -eq 1 ]; then
        exit 0 # On AC
    fi
done
exit 1 # On battery
