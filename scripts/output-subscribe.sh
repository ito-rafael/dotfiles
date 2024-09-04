#!/usr/bin/env bash
#
# This script constantly prints the focused output whenever a windows focus is changed.
#

#=================================================
# identify session (i3wm/Sway) and set vars accordingly
#=================================================

case "${XDG_SESSION_TYPE}" in
    "x11")
        WM_CMD="i3-msg"
        OUTPUT_CMD=$(i3-msg -t get_workspaces | jq -re '.[] | select(.focused).output')
        ;;
    "wayland")
        WM_CMD="swaymsg" 
        OUTPUT_CMD=$(swaymsg -t get_outputs | jq -re '.[] | select(.focused).name')
        ;;
    "tty")
        exit 0
        ;;
    *)
        exit 0
        ;;
esac

#=================================================
# get focused output
#=================================================
$WM_CMD -t subscribe -m '["window"]' | while read line; do 
    FOCUSED_OUTPUT=$OUTPUT_CMD
    echo $FOCUSED_OUTPUT
done
