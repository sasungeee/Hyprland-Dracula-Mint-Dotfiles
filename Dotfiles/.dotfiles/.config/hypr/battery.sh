#!/bin/bash

STATE="/tmp/battery_notify.state"

warn15=0
warn10=0

while true; do
    BAT=$(cat /sys/class/power_supply/BAT*/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT*/status)

    # При подключении зарядки сбрасываем состояния
    if [ "$STATUS" != "Discharging" ]; then
        warn15=0
        warn10=0
        rm -f "$STATE"
        sleep 30
        continue
    fi

    if [ "$BAT" -le 15 ] && [ "$warn15" -eq 0 ]; then
        notify-send "Battery" "15%"
        warn15=1
    fi

    if [ "$BAT" -le 10 ] && [ "$warn10" -eq 0 ]; then
        notify-send -u normal "Battery" "10%"
        warn10=1
    fi

    if [ "$BAT" -le 5 ]; then
        notify-send -u critical "Battery" "$BAT%"
        sleep 0.5
        continue
    fi

    sleep 30
done