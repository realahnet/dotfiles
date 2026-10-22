#!/usr/bin/env bash
# Time-based greeting for Waybar's custom/welcome module.
# Optional argument: an hour (0-23) to preview a specific time of day.

hour="${1:-$(date +%H)}"
if [[ "$hour" =~ ^[0-9]{1,2}$ ]] && (( 10#$hour <= 23 )); then
    hour=$((10#$hour))
else
    hour=$((10#$(date +%H)))
fi

if (( hour >= 5 && hour < 12 )); then
    icon="󰖙"   # weather-sunny
    color="#f9e2af"
    greeting="Good morning"
elif (( hour >= 12 && hour < 17 )); then
    icon="󰖙"   # weather-sunny
    color="#f9e2af"
    greeting="Good afternoon"
elif (( hour >= 17 && hour < 22 )); then
    icon="󰖚"   # weather-sunset
    color="#fab387"
    greeting="Good evening"
else
    icon="󰖔"   # weather-night
    color="#a6adc8"
    greeting="Good night"
fi

printf '<span foreground="%s" size="large">%s</span> %s, <span foreground="#888888">ahnet</span>\n' \
    "$color" "$icon" "$greeting"
