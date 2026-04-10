#!/bin/bash

# Start a temporary swayidle that turns off display after 60s of inactivity
swayidle -w -S seat0 \
    timeout 60 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' &
IDLE_PID=$!

# Lock the screen
swaylock -f

# When swaylock exits (unlocked), kill the temporary swayidle
kill $IDLE_PID 2>/dev/null
hyprctl dispatch dpms on
