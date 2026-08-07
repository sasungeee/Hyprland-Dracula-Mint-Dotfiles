#!/usr/bin/env bash

current=$(powerprofilesctl get)

perf="  Performance"
bal="  Balanced"
save="  Battery-Saver"

case "$current" in
    performance) perf="✓ Performance" ;;
    balanced)    bal="✓ Balanced" ;;
    power-saver) save="✓ Battery-Saver" ;;
esac

choice=$(
    printf "%s\n%s\n%s\n" \
        "$perf" \
        "$bal" \
        "$save" |
    rofi -dmenu -p "Power Profile" -theme ~/.config/rofi/launchers/type-2/style-1-network.rasi
)

case "$choice" in
    *Performance)
        powerprofilesctl set performance
        ;;
    *Balanced)
        powerprofilesctl set balanced
        ;;
    *Battery-Saver)
        powerprofilesctl set power-saver
        ;;
esac