#!/usr/bin/env bash
#
# This script is meant to be used with i3wm and Sway to move a window to a temporary scratchpad. Three temporary scratchpads are supported.
#
# Prerequisites:
#   i3wm:
#     - xdotool
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
	exit 0
fi

#=================================================
# parse parameters
#=================================================
SCRATCHPAD_ID=$1
ACTION=$2

#=======================================
# temporary scratchpads
#=======================================
# scratchpad tmp files
SCRATCHPAD_TEMP_1='/tmp/scratchpad_pid_1.tmp'
SCRATCHPAD_TEMP_2='/tmp/scratchpad_pid_2.tmp'
SCRATCHPAD_TEMP_3='/tmp/scratchpad_pid_3.tmp'
# set default PID to 0
TEMP_PID_1=0
TEMP_PID_2=0
TEMP_PID_3=0
#----------------------------------
# temporary scratchpad #1 (comma)
if [ -f $SCRATCHPAD_TEMP_1 ]; then
    TEMP_PID_1=$(cat $SCRATCHPAD_TEMP_1)
fi 
#----------------------------------
# temporary scratchpad #2 (period)
if [ -f $SCRATCHPAD_TEMP_2 ]; then
    TEMP_PID_2=$(cat $SCRATCHPAD_TEMP_2)
fi 
#----------------------------------
# temporary scratchpad #3 (slash)
if [ -f $SCRATCHPAD_TEMP_3 ]; then
    TEMP_PID_3=$(cat $SCRATCHPAD_TEMP_3)
fi

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
        exit 1
        ;;
esac

#=================================================
# get output resolution
#=================================================
case "${XDG_SESSION_TYPE}" in
    "x11")
        FOCUSED_OUTPUT=$(i3-msg -t get_workspaces | jq '.[] | select(.focused).output')
        WM_CMD="i3-msg"
        PROP_PREFIX="window_properties."
        PROP="class"
        CAPTION="title"
        INSTANCE="instance"
        RESOLUTION=$(i3-msg -t get_outputs | jq -r '.[] | select(.name=='"$FOCUSED_OUTPUT"')')
        RES_WIDTH=$(echo $RESOLUTION | jq '.rect.width')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.rect.height')
        OUTPUT_SCALE=1.0  # to be implemented
        ID="id"
        ID_PROP="window"
        # get window ID and convert it to PID
        WID=$(cat $SCRATCHPAD_TEMP)
        PID=$(xdotool getwindowpid $WID)
        ;;
    "wayland")
        WM_CMD="swaymsg"
        PROP="app_id"
        CAPTION="name"
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
        exit 1
        ;;
    *)
        exit 1
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
if [[ $ACTION == 'create-show' ]]; then
    # check if $SCRATCHPAD_ID file exists (i.e., if a window was previously moved to temporary scratchpad)
    #---------------------------------------
    # check if scratchpad requested is different than the focused one
    #---------------------------------------
    # get focused window
    FOCUSED_ID=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .'$ID_PROP'')
    #---------------------------------------
    if [ "$FOCUSED_ID" != "$WID" ]; then
        # then check if the {class,app_id} is one of the listed bellow
        is_scratchpad=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused) |
            .'$PROP_PREFIX''$PROP' == "dropdown_terminal" or
            .'$PROP_PREFIX''$PROP' == "dropdown_python" or
            .'$PROP_PREFIX''$PROP' == "scrcpy" and .'$PROP_PREFIX''$CAPTION' == "dropdown_scrcpy" or
            .'$PROP_PREFIX''$PROP' == "brave-music.youtube.com__-Default" or
            .'$PROP_PREFIX''$PROP' == "brave-web.whatsapp.com__-Default" or
            .'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "music.youtube.com" or
            .'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "web.whatsapp.com" or
            .'$PROP_PREFIX''$PROP' == "keymapp" or .'$PROP_PREFIX''$PROP' == "Keymapp" or
            .'$ID_PROP' == '$TEMP_PID_1' or 
            .'$ID_PROP' == '$TEMP_PID_2' or 
            .'$ID_PROP' == '$TEMP_PID_3'
            ')
        # if focused window is a scratchpad (according to the above list), hide it
        if [ "$is_scratchpad" == "true" ]; then
            $WM_CMD scratchpad show
        fi
    fi
    #---------------------------------------
    # file exists --> scratchpad already in use
    #---------------------------------------
    if [ -f $SCRATCHPAD_TEMP ]; then
        PID=$(cat $SCRATCHPAD_TEMP)
        $WM_CMD '['$ID'='$WID'] scratchpad show; ['$ID'='$WID'] resize set '$WIN_WIDTH' '$WIN_HEIGHT'; ['$ID'='$WID'] move position center'
        exit 0
    #---------------------------------------
    # file does not exist --> create scratchpad
    #---------------------------------------
    else
        WID=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .'$ID_PROP'')
        $WM_CMD '['$ID'='$WID'] floating enable; ['$ID'='$WID'] move scratchpad'
        echo $WID > $SCRATCHPAD_TEMP
    fi
#=================================================
# display temporary scratchpad if it exists
#=================================================
elif [[ $ACTION == 'display' ]]; then
    # check if $SCRATCHPAD_ID file exists (i.e., if a window was previously moved to temporary scratchpad)
    #---------------------------------------
    # check if scratchpad requested is different than the focused one
    #---------------------------------------
    # get focused window
    FOCUSED_ID=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .'$ID_PROP'')
    #---------------------------------------
    if [ "$FOCUSED_ID" != "$WID" ]; then
        # then check if the {class,app_id} is one of the listed bellow
        is_scratchpad=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused) |
            .'$PROP_PREFIX''$PROP' == "dropdown_terminal" or
            .'$PROP_PREFIX''$PROP' == "dropdown_python" or
            .'$PROP_PREFIX''$PROP' == "scrcpy" and .'$PROP_PREFIX''$CAPTION' == "dropdown_scrcpy" or
            .'$PROP_PREFIX''$PROP' == "brave-music.youtube.com__-Default" or
            .'$PROP_PREFIX''$PROP' == "brave-web.whatsapp.com__-Default" or
            .'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "music.youtube.com" or
            .'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "web.whatsapp.com" or
            .'$PROP_PREFIX''$PROP' == "keymapp" or .'$PROP_PREFIX''$PROP' == "Keymapp" or
            .'$ID_PROP' == '$TEMP_PID_1' or 
            .'$ID_PROP' == '$TEMP_PID_2' or 
            .'$ID_PROP' == '$TEMP_PID_3'
            ')
        # if focused window is a scratchpad (according to the above list), hide it
        if [ "$is_scratchpad" == "true" ]; then
            $WM_CMD scratchpad show
        fi
    fi
    #---------------------------------------
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
