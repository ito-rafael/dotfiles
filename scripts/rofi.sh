#!/usr/bin/env bash
#
# This script is meant to be used with i3wm to launch rofi in a custom way.
#
# Parameters:
#   1. rofi command: run, ssh or window
#   2. proportion used by rofi for the "padding" parameter

#=======================================
# identify session (i3wm/Sway) and set vars accordingly
#=======================================
case "${XDG_SESSION_TYPE}" in
    "x11")
        FOCUSED_OUTPUT=$(i3-msg -t get_workspaces | jq '.[] | select(.focused).output')
        WM_CMD="i3-msg"
        RESOLUTION=$(i3-msg -t get_outputs | jq -r '.[] | select(.name=='"$FOCUSED_OUTPUT"')')
        RES_WIDTH=$(echo $RESOLUTION | jq '.rect.width')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.rect.height')
        OUTPUT_SCALE=1.0  # to be implemented
        ;;
    "wayland")
        WM_CMD="swaymsg"
        RESOLUTION=$(swaymsg -t get_outputs | jq '.[] | select(.focused==true).current_mode')
        RES_WIDTH=$(echo $RESOLUTION | jq '.width')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.height')
        OUTPUT_SCALE=$(swaymsg -t get_outputs | jq '.[] | select(.focused==true).scale')
        ;;
    "tty")
        exit 1
        ;;
    *)
        exit 1
        ;;
esac

#=======================================
# get parameters
#=======================================
CMD=${1:-drun}
PROPORTION=${2-3.75}

#=======================================
# calc height & width (as int) according to the output scale
#=======================================
WIDTH=$(echo "$RES_WIDTH / $OUTPUT_SCALE" | bc)
HEIGHT=$(echo "$RES_HEIGHT / $OUTPUT_SCALE" | bc)
PAD_W=$(echo "$WIDTH / $PROPORTION" | bc)
PAD_H=$(echo "$HEIGHT / $PROPORTION" | bc)

#=======================================
# verify output orientation
#=======================================
if [ $WIN_WIDTH -gt $WIN_HEIGHT ]; then
    # horizontal monitor
    rofi -show $CMD -monitor $FOCUSED_OUTPUT -theme-str 'window {width: '$WIDTH'; height: '$HEIGHT'; padding: '$PAD_H' '$PAD_W';}'
else
    # vertical monitor
    rofi -show $CMD -monitor $FOCUSED_OUTPUT -theme-str 'window {width: '$WIDTH'; height: '$HEIGHT'; padding: '$PAD_H' '$PAD_W';}'
fi
