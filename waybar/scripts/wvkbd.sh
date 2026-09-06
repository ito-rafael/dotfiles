#!/usr/bin/env bash

STATE_FILE="/tmp/wvkbd_state.tmp"

# toggle
if [[ "$1" == "toggle" ]]; then
    if ! pgrep -x "wvkbd-deskintl" > /dev/null; then
        # not running: start it and set state to active
        swaymsg exec wvkbd-deskintl
        echo "active" > "$STATE_FILE"
    else
        # running: explicitly show or hide based on current state
        if [[ -f "$STATE_FILE" && "$(<"$STATE_FILE")" == "active" ]]; then
            pkill -SIGUSR1 -x wvkbd-deskintl # hide
            echo "inactive" > "$STATE_FILE"
        else
            pkill -SIGUSR2 -x wvkbd-deskintl # show
            echo "active" > "$STATE_FILE"
        fi
    fi
    exit 0
fi

# monitor

# create state file if it does not exist
if pgrep -x "wvkbd-deskintl" > /dev/null; then
    [[ ! -f "$STATE_FILE" ]] && echo "active" > "$STATE_FILE"
else
    [[ ! -f "$STATE_FILE" ]] && echo "inactive" > "$STATE_FILE"
fi

# function to check file existence and output JSON
update_state() {
    # fail-safe: check if the process was killed externally
    if ! pgrep -x "wvkbd-deskintl" > /dev/null; then
        echo '{"text": " ", "class": "inactive", "tooltip": "wvkbd: Off"}'
    elif [[ "$(<"$STATE_FILE")" == "active" ]]; then
        echo '{"text": " ", "class": "active", "tooltip": "wvkbd: Visible"}'
    else
        echo '{"text": " ", "class": "inactive", "tooltip": "wvkbd: Hidden"}'
    fi
}

# print initial state
update_state

# block and listen for filesystem changes in /tmp using inotify
inotifywait -q -m -e create,modify,moved_to --format '%f' /tmp | while read -r filename; do
    if [[ "$filename" == "wvkbd_state.tmp" ]]; then
        update_state
    fi
done
