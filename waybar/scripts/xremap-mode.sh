#!/usr/bin/env bash

# define systemd unit to monitor
UNIT="xremap"
# define temp file that holds the current mode
FILE="/tmp/xremap_mode.tmp"

# gracefully get current mode (prevents errors if file doesn't exist on boot)
if [[ -f "$FILE" ]]; then
    CURRENT_MODE=$(cat "$FILE")
else
    CURRENT_MODE="default"
fi

# define initial text based on the mode
if [[ "$CURRENT_MODE" == "" || "$CURRENT_MODE" == "default" ]]; then
    DEFAULT_TEXT="xremap"
else
    DEFAULT_TEXT="$CURRENT_MODE"
fi

# parse parameter
CMD=$1

case "${CMD}" in
    "monitor")
        # print initial state for Waybar
        echo "{\"text\": \"$DEFAULT_TEXT\", \"alt\": \"$CURRENT_MODE\", \"class\": \"$CURRENT_MODE\"}" || exit 0

        # internal state machine to prevent double-triggers
        TRACKED_MODE="$CURRENT_MODE"

        # infinite loop that tracks xremap mode by reading the logs
        journalctl --user -u "$UNIT" -f -n 0 | while read -r line; do

            # regex to find "mode: <MODE-NAME>"
            if [[ "$line" =~ mode:\ ([a-zA-Z0-9_-]+) ]]; then
                # extract the captured word "<MODE-NAME>"
                DETECTED_MODE="${BASH_REMATCH[1]}"

                # update Waybar only if mode changed
                if [[ "$TRACKED_MODE" != "$DETECTED_MODE" ]]; then
                    TRACKED_MODE="$DETECTED_MODE"

                    # sync temp file
                    echo "$DETECTED_MODE" > "$FILE"

                    if [[ "$DETECTED_MODE" == "default" ]]; then
                        echo '{"text": "xremap", "alt": "default", "class": "default"}' || exit 0
                    else
                        echo "{\"text\": \"$DETECTED_MODE\", \"alt\": \"$DETECTED_MODE\", \"class\": \"$DETECTED_MODE\"}" || exit 0
                    fi
                fi
            fi
        done
        ;;

    "toggle")
        # toggle between "default" and "lan-mouse" mode
        if [[ "$CURRENT_MODE" == "default" ]]; then
            # switch to =lan-mouse= mode
            ydotool key 466:1 466:0
        elif [[ "$CURRENT_MODE" == "lan-mouse" ]]; then
            # switch to =default= mode
            ydotool key 467:1 467:0
        fi
        ;;

    *)
        echo "Usage: $0 {monitor|toggle}"
        ;;
esac
