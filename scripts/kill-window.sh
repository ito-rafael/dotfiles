#!/usr/bin/env sh

# This script is used as a replacement for the "{i3-msg,swaymsg} kill" command. The focused window when this script is called is killed, even if it is a scratchpad. If the focused window is a temporary scratchpad, the temp file with its PID is also cleaned.

#=======================================
# identify environment
#=======================================

# option 1: read from env var
SESSION_TYPE=$XDG_SESSION_TYPE

# option 2: read from loginctl
#SESSION_ID=$(loginctl list-sessions -j | jq -re '.[] | select(.class == "user").session')
#SESSION_TYPE=$(loginctl show-session $SESSION_ID --property=Type --value)

case "${XDG_SESSION_TYPE}" in
    "x11")
        WM_CMD="i3-msg"
        #PROP_PREFIX="window_properties."
        #PROP="class"
        #CAPTION="title"
        #INSTANCE="instance"
        ;;
    "wayland")
        WM_CMD="swaymsg"
        #PROP="app_id"
        #CAPTION="name"
        ;;
    "tty")
        exit 1
        ;;
    *)
        exit 1
        ;;
esac

#----------------------------------
# get PID of focused window
#----------------------------------
FOCUSED_PID=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused) | .pid')

#=======================================
# temporary scratchpads
#=======================================
SCRATCHPAD_TEMP_1='/tmp/scratchpad_pid_1.tmp'
SCRATCHPAD_TEMP_2='/tmp/scratchpad_pid_2.tmp'
SCRATCHPAD_TEMP_3='/tmp/scratchpad_pid_3.tmp'
    
TEMP_PID_1=$(cat $SCRATCHPAD_TEMP_1)
TEMP_PID_2=$(cat $SCRATCHPAD_TEMP_2)
TEMP_PID_3=$(cat $SCRATCHPAD_TEMP_3)

# if focused window is a temporary scratchpad, 
# delete tmp file before killing the window.
case "${FOCUSED_PID}" in
    "$TEMP_PID_1")
        rm $SCRATCHPAD_TEMP_1
        ;;
    "$TEMP_PID_2")
        rm $SCRATCHPAD_TEMP_2
        ;;
    "$TEMP_PID_3")
        rm $SCRATCHPAD_TEMP_3
        ;;
esac

#----------------------------------
# kill the window
#----------------------------------
$WM_CMD kill
