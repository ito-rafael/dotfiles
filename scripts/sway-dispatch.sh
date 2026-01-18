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
    [Ee]macs*) emacsclient -s efs --eval "(evil-window-$DIRECTION 1)" >/dev/null 2>&1 ;;
    *) swaymsg focus "$DIRECTION" ;;
    esac
    ;;

esac
