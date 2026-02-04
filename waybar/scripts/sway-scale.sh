#!/usr/bin/env bash

# set default and get current scale
SCALE_DEFAULT="1.0"

# function to print current scale
print_scale() {
    SCALE=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .scale')
    CURRENT_SCALE=$(swaymsg -t get_outputs | jq -r '.[0].scale')
    
    IS_DEFAULT=$(echo "$CURRENT_SCALE == $SCALE_DEFAULT" | bc -l)
    if [ "$IS_DEFAULT" -eq 1 ]; then
        echo '{"text": "'$CURRENT_SCALE'", "alt": "default", "class": "default"}'
        #set_scale "$SCALE_ZOOM"
    else
        echo '{"text": "'$CURRENT_SCALE'", "alt": "zoom", "class": "zoom"}'
        #set_scale "$SCALE_DEFAULT"
    fi
}

# print init state
print_scale

# parse parameter
CMD=$1
case "${CMD}" in
    "monitor")
        # subscribe to output events
        swaymsg -m -t subscribe '["output"]' | \
        while read -r event; do
            # when any output event happens, refresh the data
            print_scale
        done
        ;;
    *)
        ;;
esac
