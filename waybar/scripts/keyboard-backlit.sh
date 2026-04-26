#!/usr/bin/env bash

# get variables
DEVICE=$(brightnessctl --list | grep kbd_backlight | cut -d "'" -f2)
FILE="/sys/class/leds/platform::kbd_backlight/brightness"
CURRENT_BRIGHTNESS=$(brightnessctl --device=$DEVICE info | grep "Current brightness" | cut -d " " -f3)
MAX_BRIGHTNESS=$(brightnessctl --device=$DEVICE info | grep "Max brightness" | cut -d " " -f3)

# helper function to print the JSON state
print_status() {
    if [ "$CURRENT_BRIGHTNESS" -eq 0 ]; then
        echo '{"text": "Off", "alt": "off", "class": "off"}'
    elif [ "$CURRENT_BRIGHTNESS" -eq "$MAX_BRIGHTNESS" ]; then
        echo '{"text": "High", "alt": "high", "class": "high"}'
    else
        # Anything in between 0 and Max is considered "low" (50%)
        echo '{"text": "Low", "alt": "low", "class": "low"}'
    fi
}

# set initial state
print_status

# infinite loop that updates everytime the keyboard brightness file changes
inotifywait --quiet --monitor --event close_write "$FILE" | while read -r _; do
    CURRENT_BRIGHTNESS=$(cat "$FILE")
    print_status
    sleep 0.1
done
