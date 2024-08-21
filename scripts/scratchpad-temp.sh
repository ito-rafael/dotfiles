#!/usr/bin/env bash
#
# This script is meant to be used with i3wm and Sway to move a window to a temporary scratchpad. Three temporary scratchpads are supported.
#
# Parameters:
#   1. ID of temporary scratchpad (options: 1, 2 or 3).
#   2. action: 
#     - "show"
#     - "destroy"

#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") action [-h]

where:
    -h, --help      show this help text
    scratchpad ID   1, 2 or 3
    action          action to be performed, can be one of the two options:
      \"show\"        show temporary scratchpad (or create it, if it doesn't exit)
      \"detach\"      detach window from scratchpad
      \"destroy\"     kill window on temporary scratchpad
"

#=================================================
# print help menu
if [[ $1 == '-h' || $1 == '--help' ]]; then
	printf "script to create, show, detach or destroy temporary scratchpad\n\n"
	echo "$usage"
	exit
fi

#=================================================
# parse parameters
#=================================================
SCRATCHPAD_ID=$1
ACTION=$2

#=================================================
# use temp file as flag to signal if scratchpad exists or not
#=================================================
#SCRATCHPAD_TEMP='/tmp/scratchpad_pid.tmp'

case "${SCRATCHPAD_ID}" in
    "1")
        SCRATCHPAD_TEMP='/tmp/scratchpad_pid_1.tmp'
        ;;
    "2")
        SCRATCHPAD_TEMP='/tmp/scratchpad_pid_2.tmp'
        ;;
    "3")
        SCRATCHPAD_TEMP='/tmp/scratchpad_pid_3.tmp'
        ;;
    *)
        echo "Scratchpad ID not supported (options available: 1, 2 or 3)."
        exit 0
        ;;
esac

#=================================================
# get output resolution
#=================================================
case "${XDG_SESSION_TYPE}" in
    "x11")
        WM_CMD="i3-msg"
        RESOLUTION=$(i3-msg -t get_outputs | jq -r '.[] | select(.name=='"$FOCUSED_OUTPUT"')')
        RES_WIDTH=$(echo $RESOLUTION | jq '.rect.width')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.rect.height')
        OUTPUT_SCALE=1.0  # TBD
        ID="id"
        ID_PROP="window"
        # get window ID and convert it to PID
        WID=$(cat $SCRATCHPAD_TEMP)
        PID=$(xdotool getwindowpid $WID)
        ;;
    "wayland")
        WM_CMD="swaymsg"
        RESOLUTION=$(swaymsg -t get_outputs | jq '.[] | select(.focused==true).current_mode')
        RES_WIDTH=$(echo $RESOLUTION | jq '.width')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.height')
        OUTPUT_SCALE=$(swaymsg -t get_outputs | jq '.[] | select(.focused==true).scale')
        ID="pid"
        ID_PROP="pid"
        # get PID directly from tmp file
        PID=$(cat $SCRATCHPAD_TEMP)
        WID=$(cat $SCRATCHPAD_TEMP)
        ;;
    "tty")
        exit 0
        ;;
    *)
        exit 0
        ;;
esac

#=================================================
# calc height & width (as int) according to the scale parameter
#=================================================
SCALE_W="0.90"
SCALE_H="0.90"
WIN_WIDTH=$(echo "$SCALE_W * $RES_WIDTH / $OUTPUT_SCALE / 1" | bc)
WIN_HEIGHT=$(echo "$SCALE_H * $RES_HEIGHT / $OUTPUT_SCALE / 1" | bc)

#=================================================
# create or show temporary scratchpad
#=================================================
if [[ $ACTION == 'show' ]]; then
    # check if $SCRATCHPAD_ID file exists (i.e., if a window was previously moved to temporary scratchpad)
    if [ -f $SCRATCHPAD_TEMP ]; then
        # file exists --> scratchpad already in use
        PID=$(cat $SCRATCHPAD_TEMP)
        $WM_CMD '['$ID'='$WID'] scratchpad show; ['$ID'='$WID'] resize set '$WIN_WIDTH' '$WIN_HEIGHT'; ['$ID'='$WID'] move position center'
        exit 0
    fi
#=================================================
# destroy temporary scratchpad
#=================================================
elif [[ $ACTION == 'destroy' ]]; then
    # kill window and delete file
    kill $PID
    rm $SCRATCHPAD_TEMP
#=================================================
# detach window from scratchpad
#=================================================
elif [[ $ACTION == 'detach' ]]; then
    if [ -f $SCRATCHPAD_TEMP ]; then
        # file exists --> detach window
        FOCUSED_PID=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused) | .'$ID_PROP'')
        # if scratchpad is focused, detach it
        if [ "$FOCUSED_PID" == "$WID" ]; then
            $WM_CMD '['$ID'='$WID'] floating disable'
        else
            # if scratchpad is not focused, display it first, then detach it
            $WM_CMD '['$ID'='$WID'] scratchpad show; floating disable'
        fi
        # delete tmp file
        rm $SCRATCHPAD_TEMP
        exit 0
    else
        # file does not exist --> ignore
        exit 0
    fi
#=================================================
else
    exit 1
fi
