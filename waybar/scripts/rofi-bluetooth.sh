#!/bin/bash

# Make sure bluetooth is powered on
bluetoothctl power on > /dev/null 2>&1

# Scan briefly for devices
bluetoothctl scan on > /dev/null 2>&1 &
SCAN_PID=$!
sleep 3
kill $SCAN_PID > /dev/null 2>&1

# Get paired devices
PAIRED=$(bluetoothctl devices Paired | sed 's/Device //g')

# Get connected device(s)
CONNECTED=$(bluetoothctl devices Connected | sed 's/Device //g')

# Build menu entries
MENU=""

if [ -n "$CONNECTED" ]; then
    while IFS= read -r line; do
        MAC=$(echo "$line" | awk '{print $1}')
        NAME=$(echo "$line" | cut -d' ' -f2-)
        MENU+="󰂱 [connected] $NAME|$MAC\n"
    done <<< "$CONNECTED"
fi

if [ -n "$PAIRED" ]; then
    while IFS= read -r line; do
        MAC=$(echo "$line" | awk '{print $1}')
        NAME=$(echo "$line" | cut -d' ' -f2-)
        # Skip if already listed as connected
        if ! echo "$CONNECTED" | grep -q "$MAC"; then
            MENU+="󰂯 $NAME|$MAC\n"
        fi
    done <<< "$PAIRED"
fi

MENU+="󰂲 Turn Bluetooth Off\n"

# Show rofi
CHOSEN=$(echo -e "$MENU" | rofi -dmenu -p "󰂯 Bluetooth" -theme-str 'window {width: 400px;}')

if [ -z "$CHOSEN" ]; then
    exit 0
fi

if echo "$CHOSEN" | grep -q "Turn Bluetooth Off"; then
    bluetoothctl power off
    notify-send "Bluetooth" "Turned off"
    exit 0
fi

MAC=$(echo "$CHOSEN" | awk -F'|' '{print $2}')
NAME=$(echo "$CHOSEN" | awk -F'|' '{print $1}' | sed 's/󰂱 \[connected\] //;s/󰂯 //')

# If connected, disconnect; if not, connect
if echo "$CHOSEN" | grep -q "\[connected\]"; then
    bluetoothctl disconnect "$MAC"
    notify-send "Bluetooth" "Disconnected from $NAME"
else
    bluetoothctl connect "$MAC"
    notify-send "Bluetooth" "Connected to $NAME"
fi
