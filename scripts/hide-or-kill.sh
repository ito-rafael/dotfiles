#!/usr/bin/env sh

#This script is used as a replacement for the "swaymsg kill" command. Instead of instantly killing a window, it first checks if the app_id is a scratchpad. If it is, it simply hides the scratchpad instead of killing it. If it is a regular window, then the window is killed normally.

SCRATCHPAD_TEMP='/tmp/scratchpad_pid.tmp'
# check if file exists
if [ -f $SCRATCHPAD_TEMP ]; then
    TEMP_PID=$(cat $SCRATCHPAD_TEMP)
else
    TEMP_PID=0
fi 

# identify environment
case "${XDG_SESSION_TYPE}" in
    "x11")
        WM_CMD="i3-msg"
        PROP_PREFIX="window_properties."
        PROP="class"
        CAPTION="title"
        INSTANCE="instance"
        ;;
    "wayland")
        WM_CMD="swaymsg"
        PROP="app_id"
        CAPTION="name"
        ;;
    "tty")
        exit 0
        ;;
    *)
        exit 0
        ;;
esac

# check if the app_id is one of the listed bellow
is_scratchpad=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused) |
    .'$PROP_PREFIX''$PROP' == "dropdown_terminal" or
    .'$PROP_PREFIX''$PROP' == "dropdown_python" or
    .'$PROP_PREFIX''$PROP' == "scrcpy" and .'$PROP_PREFIX''$CAPTION' == "dropdown_scrcpy" or
    .'$PROP_PREFIX''$PROP' == "brave-music.youtube.com__-Default" or
    .'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "music.youtube.com" or
    .'$PROP_PREFIX''$PROP' == "keymapp" or .'$PROP_PREFIX''$PROP' == "Keymapp" or
    .pid == '$TEMP_PID'
    ')

# decide whether to hide (if scratchpad) of kill the window
if [ $is_scratchpad = "true" ]; then
    $WM_CMD scratchpad show
else
    $WM_CMD kill
fi
