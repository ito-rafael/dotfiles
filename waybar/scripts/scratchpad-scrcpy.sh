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

# get device to mirror
DEVICE=$1
case "${DEVICE}" in
    "phone")
        WINDOW_TITLE="dropdown_scrcpy_phone"
        ICON=""
        ;;
    "watch")
        WINDOW_TITLE="dropdown_scrcpy_watch"
        ICON=""
        ;;
    *)
        echo "Invalid device. Exiting."
        exit 1
        ;;
esac

# check if scratchpad exists
SCRATCHPAD=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(
    .'$PROP_PREFIX''$PROP' == "scrcpy" and .'$PROP_PREFIX''$CAPTION' == "'$WINDOW_TITLE'"
    )')

# decide if icon will be displayed in color or black/white
if [[ $SCRATCHPAD ]]; then
    printf '{"text": "'$ICON'", "class": "enabled"}';
else
    printf '{"text": "'$ICON'"}';
fi
