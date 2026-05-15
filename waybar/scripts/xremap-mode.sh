#!/usr/bin/env bash

# define systemd unit to monitor
UNIT="xremap"
# define message to monitor on the output of journalctl
MODE_LANMOUSE="mode: lan-mouse"
MODE_DEFAULT="mode: default"
# define temp file that holds the current mode
FILE="/tmp/xremap_mode.tmp"

# gracefully get current mode (prevents errors if file doesn't exist on boot)
if [[ -f "$FILE" ]]; then
    CURRENT_MODE=$(cat "$FILE")
else
    CURRENT_MODE="default"
fi

# get current mode
if [[ $CURRENT_MODE == "" || $CURRENT_MODE == "default" ]]; then
    DEFAULT_TEXT="xremap"
else
    DEFAULT_TEXT=$CURRENT_MODE
fi

# parse parameter
CMD=$1

case "${CMD}" in
    "monitor")
        # print initial state
        echo '{"text": '\"$DEFAULT_TEXT\"', "alt": '\"$CURRENT_MODE\"', "class": '\"$CURRENT_MODE\"'}' || exit 0

        # internal state machine to prevent double-triggers
        TRACKED_MODE="$CURRENT_MODE"

        # infinite loop that tracks xremap mode by reading the logs of user xremap.service
        journalctl --user -u $UNIT -f -n 0 | while read -r line; do
            
            # xremap switching to =lan-mouse= mode
            if [[ "$line" == *"$MODE_LANMOUSE"* ]]; then
                if [[ "$TRACKED_MODE" != "lan-mouse" ]]; then
                    echo '{"text": "lan-mouse", "alt": "lan-mouse", "class": "lan-mouse"}' || exit 0
                    TRACKED_MODE="lan-mouse"
                fi
                
            # xremap switching to =default= mode
            elif [[ "$line" == *"$MODE_DEFAULT"* ]]; then
                if [[ "$TRACKED_MODE" != "default" ]]; then
                    #echo '{"text": "default", "alt": "default", "class": "default"}' || exit 0
                    echo '{"text": "xremap", "alt": "default", "class": "default"}' || exit 0
                    TRACKED_MODE="default"
                fi
            fi

        done
        ;;

    "toggle")
        if [[ "$CURRENT_MODE" == "default" ]]; then
            # switch to =lan-mouse= mode
            ydotool key 466:1 466:0
        elif [[ "$CURRENT_MODE" == "lan-mouse" ]]; then
            # switch to =default= mode
            ydotool key 467:1 467:0
        fi
        ;;

    *)
        ;;
esac
