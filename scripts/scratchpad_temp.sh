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

#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") action [-h]

where:
    -h, --help      show this help text
    action          action to be performed, can be one of the two options:
      \"show\"        show temporary scratchpad (or create it, if it doesn't exit)
      \"destroy\"     kill window on temporary scratchpad
"

#=================================================
# print help menu
if [[ $1 == '-h' || $1 == '--help' ]]; then
	printf "script to create, show or destroy temporary scratchpad\n\n"
	echo "$usage"
	exit
fi

#=================================================
# use temp file as flag to signal if scratchpad exists or not
SCRATCHPAD_TEMP='/tmp/scratchpad_pid.tmp'

# get output resolution
case "${XDG_SESSION_TYPE}" in
    "x11")
        WM_CMD="i3-msg"
        RESOLUTION=$(i3-msg -t get_outputs | jq -r '.[] | select(.name=='"$FOCUSED_OUTPUT"')')
        RES_WIDTH=$(echo $RESOLUTION | jq '.rect.width')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.rect.height')
        ;;
    "wayland")
        WM_CMD="swaymsg"
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

# calc height & width (as int) according to the scale parameter
SCALE_W="0.90"
SCALE_H="0.90"
WIN_WIDTH=$(echo "$SCALE_W * $RES_WIDTH / 1" | bc)
WIN_HEIGHT=$(echo "$SCALE_H * $RES_HEIGHT / 1" | bc)

#=================================================
# create or show temporary scratchpad
#=================================================
if [[ $1 == 'show' ]]; then
    # check if $SCRATCHPAD_ID file exists (i.e., if a window was previously moved to temporary scratchpad)
    if [ -f $SCRATCHPAD_TEMP ]; then
        # file exists --> scratchpad already in use
        PID=$(cat $SCRATCHPAD_TEMP)
        $WM_CMD '[pid='$PID'] scratchpad show; [pid='$PID'] resize set '$WIN_WIDTH' '$WIN_HEIGHT'; [pid='$PID'] move position center'
        exit 0
    else
        # file does not exist --> create scratchpad
        PID=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .pid')
        $WM_CMD '[pid='$PID'] floating enable; [pid='$PID'] move scratchpad'
        echo $PID > $SCRATCHPAD_TEMP
    fi
#=================================================
# destroy temporary scratchpad
#=================================================
elif [[ $1 == 'destroy' ]]; then
    kill $(cat $SCRATCHPAD_TEMP)
    rm $SCRATCHPAD_TEMP
#=================================================
else
    exit 1
fi
