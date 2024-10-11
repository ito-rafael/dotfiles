#!/usr/bin/env bash

# read Caps Lock status
CAPSLOCK_FILE="/tmp/capslock_status.tmp"

# change text everytime the brightness file changes
inotifywait --quiet --monitor --event close_write $CAPSLOCK_FILE | while read; do
    # display "Caps Lock" text, if it is enabled
    CAPSLOCK=$(cat $CAPSLOCK_FILE)
    if [[ "$CAPSLOCK" == "1" ]]; then
        echo '{"text": "  Caps Lock  ", "class": "enabled"}'
    else
        echo '{"text": ""}'
    fi
    sleep 0.1
done

