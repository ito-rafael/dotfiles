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
# identify session (i3wm/Sway) and set vars accordingly
#=======================================
case "${XDG_SESSION_TYPE}" in
    "x11")
        FOCUSED_OUTPUT=$(i3-msg -t get_workspaces | jq '.[] | select(.focused).output')
        WM_CMD="i3-msg"
        PROP_PREFIX="window_properties."
        PROP="class"
        CAPTION="title"
        INSTANCE="instance"
        ID_PROP="window"
        # get height & width of current output
        RESOLUTION=$(i3-msg -t get_outputs | jq -r '.[] | select(.name=='"$FOCUSED_OUTPUT"')')
        RES_WIDTH=$(echo $RESOLUTION | jq '.rect.width')
        RES_HEIGHT=$(echo $RESOLUTION | jq '.rect.height')
        OUTPUT_SCALE=1.0  # to be implemented
        ;;
    "wayland")
        WM_CMD="swaymsg"
        PROP="app_id"
        CAPTION="name"
        ID_PROP="pid"
        # get height & width of current output
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

# get parameters
APPLICATION=$1
SCALE_W=${2:-"0.66"}
SCALE_H=${3:-"0.66"}

# calc height & width (as int) according to the scale parameter
WIN_WIDTH=$(echo "$SCALE_W * $RES_WIDTH / $OUTPUT_SCALE / 1" | bc)
WIN_HEIGHT=$(echo "$SCALE_H * $RES_HEIGHT / $OUTPUT_SCALE / 1" | bc)

#=======================================
# get focused window
#=======================================
if [ $APPLICATION = "music.youtube.com" ] || [ $APPLICATION = "web.whatsapp.com" ]; then
    # special cases for i3wm (use "instance" instead of "class")
    #   - YouTube Music
    #   - WhatsApp Web
    FOCUSED=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .'$PROP_PREFIX''$INSTANCE'')
else
    FOCUSED=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .'$PROP_PREFIX''$PROP'')
fi

#=======================================
# check if scratchpad requested is different than the focused one
#=======================================
if [ $FOCUSED != $APPLICATION ]; then
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

#=======================================
# check if scratchpad exists
#=======================================
# special cases for i3wm (use "instance" instead of "class")
#   - YouTube Music
#   - WhatsApp Web
if [ $APPLICATION = "music.youtube.com" ] || [ $APPLICATION = "web.whatsapp.com" ]; then
    PROP="instance"
fi
# search for scratchpad
SCRATCHPAD=$($WM_CMD -t get_tree | jq -re '.. | select(type == "object") | select(.'$PROP_PREFIX''$PROP' == "'$APPLICATION'")')

#=======================================
# if it does not exist, launch it
#=======================================
if [[ ! $SCRATCHPAD ]]; then
    case "${APPLICATION}" in
        "dropdown_terminal")
            kitty --detach --class="dropdown_terminal" -o font_size=14 -o include=$XDG_CONFIG_HOME/kitty/themes/terminal.conf -o background_opacity=0.85
            sleep 0.05
            ;;
        "dropdown_python")
            kitty --detach --class="dropdown_python" -o font_size=20 -o include=$XDG_CONFIG_HOME/kitty/themes/python.conf python -q
            sleep 0.05
            ;;
        "brave-music.youtube.com__-Default")
            brave-beta --app=https://music.youtube.com &
            sleep 2
            ;;
        "brave-web.whatsapp.com__-Default")
            brave-beta --app=https://web.whatsapp.com &
            sleep 2
            ;;
        "music.youtube.com")
            brave-beta --app=https://music.youtube.com &
            sleep 2
            ;;
        "web.whatsapp.com")
            brave-beta --app=https://web.whatsapp.com &
            sleep 2
            ;;
        "keymapp")
            keymapp &
            sleep 1
            ;;
        "Keymapp")
            keymapp &
            sleep 1
            ;;
        *)
            exit 1
            ;;
    esac
fi

#=======================================
# proceed to resize, center & display requested scratchpad
#=======================================
$WM_CMD '['$PROP'='$APPLICATION'] scratchpad show; ['$PROP'='$APPLICATION'] resize set '$WIN_WIDTH' '$WIN_HEIGHT'; ['$PROP'='$APPLICATION'] move position center'

#=======================================
# set transparency for "YouTube Music" scratchpad on i3wm/Sway
#=======================================
if [ "$APPLICATION" = "brave-music.youtube.com__-Default" ] ; then
    # Sway
    sleep 0.01
    $WM_CMD '['$PROP'='$APPLICATION'] opacity set 0.9'
    exit 0
elif [ "$APPLICATION" = "music.youtube.com" ]; then
    # i3wm
    WINDOW_ID=$(i3-msg -t get_tree | jq -re '.. | select(type == "object") | select(.'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "music.youtube.com") | .window')
    picom-trans -w $WINDOW_ID -o 90
    exit 0
fi

#=======================================
# set transparency for "WhatsApp Web" scratchpad on i3wm/Sway
#=======================================
if [ "$APPLICATION" = "brave-web.whatsapp.com__-Default" ] ; then
    # Sway
    sleep 0.01
    $WM_CMD '['$PROP'='$APPLICATION'] opacity set 0.95'
    exit 0
elif [ "$APPLICATION" = "web.whatsapp.com" ]; then
    # i3wm
    WINDOW_ID=$(i3-msg -t get_tree | jq -re '.. | select(type == "object") | select(.'$PROP_PREFIX''$PROP' == "Brave-browser-beta" and .'$PROP_PREFIX''$INSTANCE' == "web.whatsapp.com") | .window')
    picom-trans -w $WINDOW_ID -o 95
    exit 0
fi
