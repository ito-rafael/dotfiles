#!/usr/bin/env bash

# read mouse warping status
FILE="/tmp/mouse_warping.tmp"
MOUSE_WARPING=$(cat $FILE)

# parse parameter
CMD=$1

case "${CMD}" in
    "monitor")
        # set initial state
        if [[ "$MOUSE_WARPING" == "1" ]]; then
            echo '{"text": "", "alt": "enabled", "class": "enabled"}'
        else
            echo '{"text": "", "alt": "disabled", "class": "disabled"}'
        fi

        # infinite loop that changes text everytime the mouse warping file changes
        inotifywait --quiet --monitor --event close_write $FILE | while read; do
            MOUSE_WARPING=$(cat $FILE)
            if [[ "$MOUSE_WARPING" == "1" ]]; then
                echo '{"text": "", "alt": "enabled", "class": "enabled"}'
            else
                echo '{"text": "", "alt": "disabled", "class": "disabled"}'
            fi
            sleep 0.1
        done
        ;;
    "toggle")
        if [[ "$MOUSE_WARPING" == "1" ]]; then
            # disable mouse warping
            swaymsg mouse_warping none
            echo 0 > $FILE
        else
            # enable mouse warping
            swaymsg mouse_warping container
            echo 1 > $FILE
        fi
        ;;
    *)
        ;;
esac
