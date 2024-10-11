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

# check if scratchpad exists
SCRATCHPAD=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(
    .'$PROP_PREFIX''$PROP' == "brave-web.whatsapp.com__-Default" or
    .'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "web.whatsapp.com"
    )')

# decide if icon will be displayed in color or black/white
if [[ $SCRATCHPAD ]]; then
    printf '{"text": "", "class": "enabled"}';
else
	printf '{"text": ""}';
fi
