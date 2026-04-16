#!/usr/bin/env bash

# define min/max temperature
TEMP_MIN=2000
TEMP_MAX=6500

# define where to store the current temperature state
STATE_FILE="/tmp/gamma_temp.tmp"

# set a default starting temperature if the file doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo $TEMP_MAX > "$STATE_FILE"
fi

# read current temperature
CURRENT_TEMP=$(cat "$STATE_FILE")

# adjust temperature based on the argument passed (+ or -)
if [ "$1" == "inc" ]; then
    NEW_TEMP=$((CURRENT_TEMP + 500))
elif [ "$1" == "dec" ]; then
    NEW_TEMP=$((CURRENT_TEMP - 500))
else
    echo "Usage: gamma-adjust [inc|dec]"
    exit 1
fi

# set limits
if [ "$NEW_TEMP" -gt $TEMP_MAX ]; then NEW_TEMP=$TEMP_MAX; fi
if [ "$NEW_TEMP" -lt $TEMP_MIN ]; then NEW_TEMP=$TEMP_MIN; fi

# save the new temperature
echo "$NEW_TEMP" > "$STATE_FILE"

# seamlessly restart gammastep with the new value
killall gammastep 2>/dev/null
gammastep -O "$NEW_TEMP" > /dev/null 2>&1 &

# wait a fraction of a second for Gammastep to grab the Wayland display
sleep 0.2

# send Real-Time Signal 8 to Waybar to force an instant refresh
pkill -RTMIN+8 waybar
