#!/bin/sh

'''
This script is used as a replacement for the "swaymsg kill" command. Instead of
instantly killing a window, it first checks if the app_id is a scratchpad. If
it is, it simply hides the scratchpad instead of killing it. If it is a regular
window, then the window is killed normally.
'''

# check if the app_id is one of the listed bellow
is_scratchpad=$(swaymsg -t get_tree | jq -re '.. | select(type == "object") | select(.focused) |
    .app_id == "dropdown_terminal" or
    .app_id == "dropdown_python" or
    .app_id == "scrcpy" and .name == "dropdown_scrcpy" 
    ')

# decide whether to hide (if scratchpad) of kill the window
if [ $is_scratchpad = "true" ]; then
    swaymsg scratchpad show
else
    swaymsg kill
fi
