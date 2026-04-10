#!/bin/bash

# Get list of available networks
NETWORKS=$(nmcli -f SSID,SECURITY,SIGNAL device wifi list | tail -n +2 | awk '{printf "%-40s %-15s %s\n", $1, $2, $3}')

# Show rofi menu
CHOSEN=$(echo "$NETWORKS" | rofi -dmenu -p "󰤨 WiFi" -theme-str 'window {width: 500px;}')

if [ -z "$CHOSEN" ]; then
    exit 0
fi

SSID=$(echo "$CHOSEN" | awk '{print $1}')

# Check if already connected
CURRENT=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
if [ "$CURRENT" = "$SSID" ]; then
    notify-send "WiFi" "Already connected to $SSID"
    exit 0
fi

# Check if network requires password
SECURITY=$(echo "$CHOSEN" | awk '{print $2}')

# Try to connect (uses saved credentials if available)
RESULT=$(nmcli device wifi connect "$SSID" 2>&1)

if echo "$RESULT" | grep -q "successfully activated"; then
    notify-send "WiFi" "Connected to $SSID"
elif echo "$RESULT" | grep -q "Secrets were required"; then
    # Ask for password via rofi
    PASSWORD=$(rofi -dmenu -p "🔒 Password for $SSID" -password -theme-str 'window {width: 400px;}')
    if [ -z "$PASSWORD" ]; then
        exit 0
    fi
    RESULT=$(nmcli device wifi connect "$SSID" password "$PASSWORD" 2>&1)
    if echo "$RESULT" | grep -q "successfully activated"; then
        notify-send "WiFi" "Connected to $SSID"
    else
        notify-send "WiFi" "Failed to connect to $SSID"
    fi
else
    notify-send "WiFi" "Failed to connect to $SSID"
fi
