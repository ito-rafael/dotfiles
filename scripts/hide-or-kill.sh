#!/usr/bin/env sh

#This script is used as a replacement for the "swaymsg kill" command. Instead of instantly killing a window, it first checks if the app_id is a scratchpad. If it is, it simply hides the scratchpad instead of killing it. If it is a regular window, then the window is killed normally.

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

#=======================================
# identify environment
#=======================================
case "${XDG_SESSION_TYPE}" in
    "x11")
        WM_CMD="i3-msg"
        PROP_PREFIX="window_properties."
        PROP="class"
        CAPTION="title"
        INSTANCE="instance"
        ID_PROP="window"
        ;;
    "wayland")
        WM_CMD="swaymsg"
        PROP="app_id"
        CAPTION="name"
        ID_PROP="pid"
        ;;
    "tty")
        exit 0
        ;;
    *)
        exit 0
        ;;
esac

#=======================================
# check if the app_id is one of the listed bellow
#=======================================
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

# decide whether to hide (if scratchpad) of kill the window
if [ $is_scratchpad = "true" ]; then
    $WM_CMD scratchpad show
else
    # special case for applications that keep a PID temp file
    APPLICATION=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused) | .'$PROP_PREFIX''$PROP'')

    # delete temp PID file
    case $APPLICATION in
        # Show Me The Key
        "one.alynx.showmethekey")
            rm /tmp/showmethekey_pid.tmp
            ;;
        *)
            ;;
    esac

    # kill window
    $WM_CMD kill
fi
