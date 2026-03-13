#!/usr/bin/env bash

LANMOUSE_FILE="/tmp/lanmouse-status.tmp"

# function to print lan-mouse status
print_status() {
    LANMOUSE_STATUS=$(cat $LANMOUSE_FILE)
    if [[ "$LANMOUSE_STATUS" == "disconnected" ]]; then
        echo '{"text": "", "class": "disconnected"}'
    elif [[ "$LANMOUSE_STATUS" == "connected" ]]; then
        echo '{"text": "", "class": "connected"}'
    elif [[ "$LANMOUSE_STATUS" == "active" ]]; then
        echo '{"text": "", "class": "active"}'
    else
        echo '{"text": "", "class": "unknown"}'
    fi
}

# print current status
print_status

# change text everytime the lanmouse status file changes
inotifywait --quiet --monitor --event close_write $LANMOUSE_FILE | while read; do
    print_status
    sleep 0.1
done


# function to print current scale
print_scale() {
    SCALE=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .scale')
    CURRENT_SCALE=$(swaymsg -t get_outputs | jq -r '.[0].scale')

    IS_DEFAULT=$(echo "$CURRENT_SCALE == $SCALE_DEFAULT" | bc -l)
    if [ "$IS_DEFAULT" -eq 1 ]; then
        echo '{"text": "'$CURRENT_SCALE'", "alt": "default", "class": "default"}'
    else
        echo '{"text": "'$CURRENT_SCALE'", "alt": "zoom", "class": "zoom"}'
    fi
}

# print init state
print_scale

# subscribe to output events
swaymsg -m -t subscribe '["output"]' | \
while read -r event; do
    # when any output event happens, refresh the data
    print_scale
done
