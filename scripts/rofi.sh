#!/usr/bin/env bash
#
# This script is meant to be used with i3wm/Sway/Hyprland to launch rofi in a custom way.
#
# Parameters:
#   1. rofi command: run, ssh or window
#   2. proportion used by rofi for the "padding" parameter

#=======================================
# get parameters
#=======================================
CMD=${1:-drun}
PROPORTION=${2:-3.75}

#=======================================
# identify session (i3wm/Sway/Hyprland) and set vars accordingly
#=======================================
case "${XDG_SESSION_TYPE}" in
    "x11")
        FOCUSED_OUTPUT=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).output')
        WM_CMD="i3-msg"
        RESOLUTION=$(i3-msg -t get_outputs | jq '.[] | select(.name=="'$FOCUSED_OUTPUT'")')
        WIDTH=$(echo "$RESOLUTION" | jq '.rect.width')
        HEIGHT=$(echo "$RESOLUTION" | jq '.rect.height')
        ;;
    "wayland")
        if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
            WM_CMD="hyprctl"
            FOCUSED_MONITOR=$(hyprctl monitors -j | jq '.[] | select(.focused == true)')
            FOCUSED_OUTPUT=$(echo "$FOCUSED_MONITOR" | jq -r '.name')

            # Hyprland outputs physical pixels and a scale factor.
            # We calculate the logical pixels to match Sway's behavior.
            RAW_WIDTH=$(echo "$FOCUSED_MONITOR" | jq '.width')
            RAW_HEIGHT=$(echo "$FOCUSED_MONITOR" | jq '.height')
            SCALE=$(echo "$FOCUSED_MONITOR" | jq '.scale')

            WIDTH=$(awk "BEGIN {print int($RAW_WIDTH / $SCALE)}")
            HEIGHT=$(awk "BEGIN {print int($RAW_HEIGHT / $SCALE)}")
        else
            # Fallback to Sway
            WM_CMD="swaymsg"
            RESOLUTION=$(swaymsg -t get_outputs | jq '.[] | select(.focused==true)')
            FOCUSED_OUTPUT=$(echo "$RESOLUTION" | jq -r '.name')
            WIDTH=$(echo "$RESOLUTION" | jq '.rect.width')
            HEIGHT=$(echo "$RESOLUTION" | jq '.rect.height')
        fi
        ;;
    "tty")
        exit 1
        ;;
    *)
        exit 1
        ;;
esac

#=======================================
# calc height & width (as int) according to the output scale
#=======================================
PAD_W=$(echo "$WIDTH / $PROPORTION" | bc)
PAD_H=$(echo "$HEIGHT / $PROPORTION" | bc)

#=======================================
# verify output orientation
#=======================================
if [ "$WIDTH" -gt "$HEIGHT" ]; then
    # horizontal monitor
    exec rofi -show "$CMD" -monitor "$FOCUSED_OUTPUT" -theme-str 'window {fullscreen: true; width: '"$WIDTH"'px; height: '"$HEIGHT"'px; padding: '"$PAD_H"'px '"$PAD_W"'px;}'
else
    # vertical monitor
    exec rofi -show "$CMD" -monitor "$FOCUSED_OUTPUT" -theme-str 'window {fullscreen: true; width: '"$WIDTH"'px; height: '"$HEIGHT"'px; padding: '"$PAD_H"'px '"$PAD_W"'px;}'
fi
