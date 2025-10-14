#!/usr/bin/env bash

# This script is used to adjust the volume in fixed step sizes.
#
# Required parameter:
#   - str [up,down] direction
# Optional parameter:
#   - int [1~100]: step size (default: 25%)
#

#=================================================
# help menu and usage message
#=================================================

usage="$(basename "$0") [-h] direction [-S,--step]

where:
    -h, --help  show this help text
    direction   "up" for increasing, and "down" for decreasing the volume.
    --step, -S  int [1,100] adjust volume in multiples
"
#------------------------
# print help menu
if [[ $1 == '-h' || $1 == '--help' ]]; then
	printf "script to adjust volume in fixed step sizes\n\n"
	echo "$usage"
	exit
#------------------------
# parse arguments
else
    DIRECTION=$1
    STEP=$2
    #------------------------
    # validate if direction is "up" or "down"
    if [[ "$DIRECTION" != "up" && "$DIRECTION" != "down" ]]; then
        echo "Usage: $0 <up|down> <step>"
        exit 1
    fi
    #------------------------
    # validate step or assign default value
    if ! [[ "$STEP" =~ ^[0-9]+$ && "$STEP" -gt 0 && "$STEP" -le 100 ]]; then
        #echo "Error: step must be a number between 1 and 100."
        #exit 1
        STEP="25"
    fi
    #------------------------
    # get current volume level
    CURRENT_VOL=$(amixer get Master | awk -F'[][]' '/%/ {print $2}' | head -n1 | tr -d '%')
    #------------------------
    # calculate new volume
    if [[ "$DIRECTION" == "up" ]]; then
        NEW_VOL=$(( ((CURRENT_VOL / STEP) + 1) * STEP ))
        [[ $NEW_VOL -gt 100 ]] && NEW_VOL=100
    else    
        NEW_VOL=$(( ((CURRENT_VOL - 1) / STEP) * STEP ))
        [[ $NEW_VOL -lt 0 ]] && NEW_VOL=0
    fi
    #------------------------
    # set new volume
    amixer -q sset Master "${NEW_VOL}%"
    #------------------------
fi
