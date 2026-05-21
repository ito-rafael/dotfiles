#!/usr/bin/env bash

PID_FILE="/tmp/showmethekey_pid.tmp"

# function to check file existence and output JSON
update_state() {
    if [ -f "$PID_FILE" ]; then
        # file exists: output space and active class
        echo '{"text": " ", "class": "active", "tooltip": "ShowMeTheKey: on"}'
    else
        # file missing: output space and inactive class
        echo '{"text": " ", "class": "inactive", "tooltip": "ShowMeTheKey: off"}'
    fi
}

# print initial state
update_state

# block and listen for filesystem changes in /tmp using inotify
# we only listen to {create,delete,move} events, and we output just the filename (%f)
inotifywait -q -m -e create,delete,moved_to,moved_from --format '%f' /tmp | while read -r filename; do
    # when any file is {created,deleted} in /tmp, check if it's showmethekey_pid.tmp
    if [[ "$filename" == "showmethekey_pid.tmp" ]]; then
        update_state
    fi
done
