#!/usr/bin/env bash
#
# This script is meant to be used with i3wm to show/hide scratchpads.
# When displaying the scratchpad, it resizes the window according to the parameters received and center the window.
#
# Parameters:
#   1. APPLICATION: $prop ("class" for i3wm, "app_id" for Sway) of the window. Example: "dropdown_terminal".
#   2. SCALE_W: scale multiplier for the scratchpad width. Example: 0.75 (default: 0.66).
#   3. SCALE_H: scale multiplier for the scratchpad height. Example: 0.90 (default: 0.66).
#

# identify session (i3wm/Sway) and set vars accordingly
case "${XDG_SESSION_TYPE}" in
    "x11")
        FOCUSED_OUTPUT=$(i3-msg -t get_workspaces | jq '.[] | select(.focused).output')
        WM_CMD="i3-msg"
        PROP="class"
        CAPTION="title"
        # get height & width of current output
        RESOLUTION=$(i3-msg -t get_outputs | jq -r '.[] | select(.name=='"$FOCUSED_OUTPUT"')')
        RES_WIDTH=$(echo $RESOLUTION | jq '.rect.width')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.rect.height')
        ;;
    "wayland")
        WM_CMD="swaymsg"
        PROP="app_id"
        CAPTION="name"
        # get height & width of current output
        RESOLUTION=$(swaymsg -t get_outputs | jq '.[] | select(.focused==true).current_mode')
        RES_WIDTH=$(echo $RESOLUTION | jq '.width')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.height')
        ;;
    "tty")
        exit 0
        ;;
    *)
        exit 0
        ;;
esac

# get parameters
APPLICATION=$1
SCALE_W=${2:-"0.66"}
SCALE_H=${3:-"0.66"}

# calc height & width (as int) according to the scale parameter
WIN_WIDTH=$(echo "$SCALE_W * $RES_WIDTH / 1" | bc)
WIN_HEIGHT=$(echo "$SCALE_H * $RES_HEIGHT / 1" | bc)

# get focused window
FOCUSED=$(swaymsg -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .app_id')

# check if scratchpad requested is different than the focused one
if [ $FOCUSED != $APPLICATION ]; then
    # then check if the app_id is one of the listed bellow
    is_scratchpad=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused) |
        .'$PROP' == "dropdown_terminal" or
        .'$PROP' == "dropdown_python" or
        .'$PROP' == "scrcpy" and .'$CAPTION' == "dropdown_scrcpy" or
        .'$PROP' == "brave-music.youtube.com__-Default"
        ')

    # if focused window is a scratchpad (according to the above list), hide it
    if [ $is_scratchpad = "true" ]; then
        $WM_CMD scratchpad show
    fi
fi

# proceed to resize, center & display requested scratchpad
$WM_CMD '['$PROP'='$APPLICATION'] scratchpad show; ['$PROP'='$APPLICATION'] resize set '$WIN_WIDTH' '$WIN_HEIGHT'; ['$PROP'='$APPLICATION'] move position center'

# set transparency for "YouTube Music" scratchpad
if [ $APPLICATION = "brave-music.youtube.com__-Default" ]; then
    sleep 0.01
    $WM_CMD '['$PROP'='$APPLICATION'] opacity set 0.9'
fi
