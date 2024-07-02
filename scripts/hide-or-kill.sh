#!/usr/bin/env sh

'''
This script is used as a replacement for the "swaymsg kill" command. Instead of instantly killing a window, it first checks if the app_id is a scratchpad. If it is, it simply hides the scratchpad instead of killing it. If it is a regular window, then the window is killed normally.
'''

# identify environment
case "${XDG_SESSION_TYPE}" in
    "x11")
        WM_CMD="i3-msg"
        PROP="window_properties.class"
        CAPTION="window_properties.title"
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

# check if the app_id is one of the listed bellow
is_scratchpad=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused) |
    .'$PROP' == "dropdown_terminal" or
    .'$PROP' == "dropdown_python" or
    .'$PROP' == "scrcpy" and .'$CAPTION' == "dropdown_scrcpy" or
    .'$PROP' == "brave-music.youtube.com__-Default"
    ')

# decide whether to hide (if scratchpad) of kill the window
if [ $is_scratchpad = "true" ]; then
    $WM_CMD scratchpad show
else
    $WM_CMD kill
fi
