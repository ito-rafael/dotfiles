#!/usr/bin/env bash
#
# This script is used to control the status of the Caps Lock.
# It is used by the status bar (Waybar)
#
#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") destination action [-h]

where:
    -h, --help      show this help text
    action          action to be performed, can be one of the following options:
      \"status\"      returns the status of the Caps Lock key
      \"on\"          set Caps Lock on
      \"off\"         set Caps Lock off
      \"toggle\"      toggles the status of Caps Lock
"
#=================================================
# print help menu
if [[ $1 == '-h' || $1 == '--help' || $1 == '' ]]; then
    printf "Script to control the status of the Caps Lock key.\n\n"
    echo "$usage"
    exit
fi

#=================================================
# parse parameters
ACTION=$1
CAPSLOCK_FILE='/tmp/capslock_status.tmp'

# read Caps Lock brightness LED
PATH_PREFIX="/sys/class/leds"
CAPSLOCK_INPUT=$(ls $PATH_PREFIX | grep capslock | sort -V | head -n1)
BRIGHTNESS_FILE=$PATH_PREFIX"/"$CAPSLOCK_INPUT"/brightness"
BRIGHTNESS=$(cat $BRIGHTNESS_FILE)

#=================================================
# function to toggle Caps Lock
toggle_caps(){
    ydotool key 58:1 58:0
}

# perform action requested
case "${ACTION}" in
    "status")
        echo $BRIGHTNESS
        exit 0
        ;;
    "on")
        if [[ "$BRIGHTNESS" == "0" ]]; then
            echo 1 > $CAPSLOCK_FILE
            #echo 1 > $BRIGHTNESS_FILE
            toggle_caps
        fi
        exit 0
        ;;
    "off")
        if [[ "$BRIGHTNESS" == "1" ]]; then
            echo 0 > $CAPSLOCK_FILE
            #echo 0 > $BRIGHTNESS_FILE
            toggle_caps
        fi
        exit 0
        ;;
    "toggle")
        if [[ "$BRIGHTNESS" == "0" ]]; then
            echo 1 > $CAPSLOCK_FILE
        else
            echo 0 > $CAPSLOCK_FILE
        fi
        toggle_caps
        exit 0
        ;;
    *)
        echo "Option no supported. Exiting..."
        exit 1
        ;;
esac
