#!/usr/bin/env bash

# identify session (i3wm/Sway) and set vars accordingly
case "${XDG_SESSION_TYPE}" in
    "x11")
        WM_CMD="i3-msg"
        PROP_PREFIX="window_properties."
        PROP="class"
        CAPTION="title"
        INSTANCE="instance"
        ;;
    "wayland")
        WM_CMD="swaymsg"
        PROP="app_id"
        CAPTION="name"
        ;;
    "tty")
        exit 0
        ;;
    *)
        exit 0
        ;;
esac

# parse parameters
COLOR=$1
GRAY=555

# check if scratchpad exists
SCRATCHPAD=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(
    .'$PROP_PREFIX''$PROP' == "keymapp" or .'$PROP_PREFIX''$PROP' == "Keymapp"
    )')

# decide if icon will be displayed in color or black/white
if [[ $SCRATCHPAD ]]; then
    echo "%{F#$COLOR}%{F-}"
else
    echo "%{F#$GRAY}%{F-}"
fi
