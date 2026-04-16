#!/usr/bin/env bash

TEMP_MIN=2000
TEMP_MAX=6500

# define where to store the current temperature state
STATE_FILE="/tmp/gammastep_temp"

# set a default starting temperature if the file doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo 6500 > "$STATE_FILE"
fi

# read current temperature
CURRENT_TEMP=$(cat "$STATE_FILE")

# adjust temperature based on the argument passed (+ or -)
if [ "$1" == "up" ]; then
    NEW_TEMP=$((CURRENT_TEMP + 500))
elif [ "$1" == "down" ]; then
    NEW_TEMP=$((CURRENT_TEMP - 500))
else
    echo "Usage: gamma-adjust [up|down]"
    exit 1
fi

# set limits (e.g., don't go above 6500K or below 2000K)
if [ "$NEW_TEMP" -gt $TEMP_MAX ]; then NEW_TEMP=$TEMP_MAX; fi
if [ "$NEW_TEMP" -lt $TEMP_MIN ]; then NEW_TEMP=$TEMP_MIN; fi

# Save the new temperature
echo "$NEW_TEMP" > "$STATE_FILE"

# Seamlessly restart gammastep with the new value
killall gammastep 2>/dev/null
gammastep -O "$NEW_TEMP" > /dev/null 2>&1 &
