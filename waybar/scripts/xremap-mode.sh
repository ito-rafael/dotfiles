#!/usr/bin/env bash

# define systemd unit to monitor
UNIT="xremap"
# define message to monitor on the output of journalctl
MODE_LANMOUSE="mode: lan-mouse"
MODE_DEFAULT="mode: default"
# set cooldown (in miliseconds) to avoid double trigger
COOLDOWN=250
LAST_TRIGGER=0

# get current mode
FILE="/tmp/xremap_mode.tmp"
CURRENT_MODE=$(cat $FILE)
if [[ $CURRENT_MODE == "" || $CURRENT_MODE == "default" ]]; then
    DEFAULT_TEXT="xremap"
else
    DEFAULT_TEXT=$CURRENT_MODE
fi

# parse parameter
CMD=$1

case "${CMD}" in
    "monitor")
        echo '{"text": '\"$DEFAULT_TEXT\"', "alt": '\"$CURRENT_MODE\"', "class": '\"$CURRENT_MODE\"'}'
        journalctl --user -u $UNIT -f -n 0 | while read -r line; do
            CURRENT_TIME=$(($(date +%s%N) / 1000000))
            
            # xremap switching to =lan-mouse= mode
            if [[ "$line" == *"$MODE_LANMOUSE"* ]]; then
                # check if enough time (cooldown) has passed since the last trigger
                if ((CURRENT_TIME - LAST_TRIGGER >= COOLDOWN)); then
                    echo '{"text": "lan-mouse", "alt": "lan-mouse", "class": "lan-mouse"}'
                    LAST_TRIGGER=$CURRENT_TIME
                fi
                
            # xremap switching to =default= mode
            elif [[ "$line" == *"$MODE_DEFAULT"* ]]; then
                # check if enough time (cooldown) has passed since the last trigger
                if ((CURRENT_TIME - LAST_TRIGGER >= COOLDOWN)); then
                    #echo '{"text": "default", "alt": "default", "class": "default"}'
                    echo '{"text": "xremap", "alt": "default", "class": "default"}'
                    LAST_TRIGGER=$CURRENT_TIME
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
