#!/usr/bin/env bash

# read Caps Lock status
CAPSLOCK_FILE="/tmp/capslock_status.tmp"

# change text everytime the brightness file changes
inotifywait --quiet --monitor --event close_write $CAPSLOCK_FILE | while read; do
    # display "Caps Lock" text, if it is enabled
    CAPSLOCK=$(cat $CAPSLOCK_FILE)
    if [[ "$CAPSLOCK" == "1" ]]; then
        #echo '{"text": "  Caps Lock  ", "class": "enabled"}'
        echo '{"text": "", "class": "enabled"}'
        # change Waybar color to mint green
        echo '@define-color dynamic_bg rgba(151, 225, 173, 0.75);' > ~/.config/waybar/dynamic-bg.css
    else
        echo '{"text": ""}'
        # reset Waybar color
        echo '@define-color dynamic_bg rgba(43, 48, 59, 0.5);' > ~/.config/waybar/dynamic-bg.css
    fi
    sleep 0.1
done
