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

# dynamically determine the current temperature based on the active mode
if pgrep -f "gammastep -O" > /dev/null; then
    CURRENT_MODE="manual"
    # currently in manual mode: read from the state file
    CURRENT_TEMP=$(cat "$STATE_FILE")
else
    CURRENT_MODE="auto"
    # currently in auto mode: fetch the real active temperature
    CURRENT_TEMP=$(gammastep -p 2>&1 | grep "Color temperature" | grep -o "[0-9]*")

    # fallback to the state file just in case the fetch fails
    if [[ ! "$CURRENT_TEMP" =~ ^[0-9]+$ ]]; then
        CURRENT_TEMP=$(cat "$STATE_FILE")
    fi
fi

# adjust temperature or toggle mode based on the argument passed
case "$1" in
    inc)
        NEW_TEMP=$((CURRENT_TEMP + 500))
        ;;
    dec)
        NEW_TEMP=$((CURRENT_TEMP - 500))
        ;;
    toggle)
        if [ "$CURRENT_MODE" == "manual" ]; then
            # currently in manual mode (-O), switch back to auto mode
            killall gammastep 2>/dev/null
            gammastep > /dev/null 2>&1 &

            # fetch current automatic temperature and update the state file
            AUTO_TEMP=$(gammastep -p 2>&1 | grep "Color temperature" | grep -o "[0-9]*")
            if [[ "$AUTO_TEMP" =~ ^[0-9]+$ ]]; then
                echo "$AUTO_TEMP" > "$STATE_FILE"
            fi
        else
            # currently in auto mode, switch to manual mode using the exact current temp
            killall gammastep 2>/dev/null
            gammastep -O "$CURRENT_TEMP" > /dev/null 2>&1 &
        fi

        # wait a fraction of a second and update Waybar, then exit script
        sleep 0.2
        pkill -RTMIN+8 waybar
        exit 0
        ;;
    *)
        echo "Usage: gamma-adjust [inc|dec|toggle]"
        exit 1
        ;;
esac

# the following code only runs for the 'inc' and 'dec' arguments

# set limits
if [ "$NEW_TEMP" -gt $TEMP_MAX ]; then NEW_TEMP=$TEMP_MAX; fi
if [ "$NEW_TEMP" -lt $TEMP_MIN ]; then NEW_TEMP=$TEMP_MIN; fi

# save the new temperature
echo "$NEW_TEMP" > "$STATE_FILE"

# seamlessly restart gammastep with the new value (forces manual mode)
# Apply the wait flag ONLY if transitioning from auto mode
if [ "$CURRENT_MODE" == "auto" ]; then
    killall --wait gammastep 2>/dev/null
else
    killall gammastep 2>/dev/null
fi

gammastep -O "$NEW_TEMP" > /dev/null 2>&1 &

# wait a fraction of a second for Gammastep to grab the Wayland display
sleep 0.2

# send Real-Time Signal 8 to Waybar to force an instant refresh
pkill -RTMIN+8 waybar
