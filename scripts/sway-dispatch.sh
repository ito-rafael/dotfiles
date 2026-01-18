#!/usr/bin/env bash

# Usage:
# ./smart_dispatch.sh focus left
# ./smart_dispatch.sh type symbol
# ./smart_dispatch.sh launch

COMMAND="$1"
PARAM="$2"

# get the app_id of the focused window
# some XWayland apps might have null app_id, so we fallback to window_properties.class if needed
FOCUSED_APP=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | if .app_id then .app_id else .window_properties.class end')

case "$COMMAND" in

"focus")
    DIRECTION="$PARAM"
    case "$FOCUSED_APP" in
    [Ee]macs*)
        case "$DIRECTION" in
        "left") ydotool key 29:1 17:1 17:0 29:0 29:1 35:1 35:0 29:0 ;;  # C-w C-h
        "down") ydotool key 29:1 17:1 17:0 29:0 29:1 36:1 36:0 29:0 ;;  # C-w C-j
        "up") ydotool key 29:1 17:1 17:0 29:0 29:1 37:1 37:0 29:0 ;;    # C-w C-k
        "right") ydotool key 29:1 17:1 17:0 29:0 29:1 38:1 38:0 29:0 ;; # C-w C-l
        esac
        ;;
    *) swaymsg focus "$DIRECTION" ;;
    esac
    ;;

esac
