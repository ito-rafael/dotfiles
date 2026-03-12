#!/usr/bin/env bash

LANMOUSE_FILE="/tmp/lanmouse-status.tmp"

# function to print lan-mouse status
print_status() {
    LANMOUSE_STATUS=$(cat $LANMOUSE_FILE)
    if [[ "$LANMOUSE_STATUS" == "connected" ]]; then
        echo '{"text": "", "class": "connected"}'
    elif [[ "$LANMOUSE_STATUS" == "disconnected" ]]; then
        echo '{"text": "", "class": "disconnected"}'
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
