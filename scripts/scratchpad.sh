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
        # get height & width of current output
        RESOLUTION=$(i3-msg -t get_outputs | jq -r '.[] | select(.name=='"$FOCUSED_OUTPUT"')')
        RES_WIDTH=$(echo $RESOLUTION | jq '.rect.width')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.rect.height')
        ;;
    "wayland")
        WM_CMD="swaymsg"
        PROP="app_id"
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

# resize, center & display scratchpad
$WM_CMD '['$PROP'='$APPLICATION'] scratchpad show; ['$PROP'='$APPLICATION'] resize set '$WIN_WIDTH' '$WIN_HEIGHT'; ['$PROP'='$APPLICATION'] move position center'
