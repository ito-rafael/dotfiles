#!/usr/bin/env bash
#
# This script start/stop/toggle the status of the screencast tool. 
# The parameters are:
#   - start: start the tool (or ignore if it's already running)
#   - stop: stop the tool (or ignore if it's already stopped)
#   - toggle:
#     - if the tool is running, this script kills it.
#     - if the tool is not running, this script launches it.
#
# The tool is chosen according to the environment:
#   - (deprecated) for X11: screenkey (https://gitlab.com/screenkey/screenkey)
#   - (deprecated) for Wayland: wshowkeys (https://github.com/ammgws/wshowkeys)
#   - for both X11/Wayland: showmethekey (https://github.com/AlynxZhou/showmethekey)
#
# Installation:
#   Arch:
#     - (deprecated) sudo pacman -S screenkey
#     - (deprecated) paru -S wshowkeys-git
#     - paru -S showmethekey
#
#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") action [-h]

where:
    -h, --help      show this help text
    action          action to be performed, can be one of the three options:
      \"start\"       start showmethekey (if it's not already running)
      \"stop\"        stop showmethekey
      \"toggle\"      toggle showmethekey status (start if it's not running, stop if it is)
"
#=================================================
# print help menu
if [[ $1 == '-h' || $1 == '--help' || $1 == '' ]]; then
    printf "Script to start, stop or toggle the state of the screencast tool (Show Me The Key).\n\n"
    echo "$usage"
    exit
fi

#=================================================
# parse parameters
ACTION=$1
PID_FILE='/tmp/showmethekey_pid.tmp'

case "${ACTION}" in
    "start")
        # check if it's already running
        if [ -f $PID_FILE ]; then
            # ignore
            echo "PID file already exists. Exiting..."
            exit 0
        else
            # start application and save its PID to file
            echo "Starting application..."
            showmethekey-gtk & 
            echo $! > $PID_FILE 
            exit 0
        fi
        ;;
    "stop")
        # check if it's already running
        if [ -f $PID_FILE ]; then
            # stop and remove PID file
            echo "Stopping application..."
            PID=$(cat "$PID_FILE")
            rm $PID_FILE
            kill $PID
            exit 0
        else
            # ignore
            echo "PID file does not exist. Exiting..."
            exit 0
        fi
        ;;
    "toggle")
        # check if it's already running
        if [ -f $PID_FILE ]; then
            # stop and remove PID file
            echo "Stopping application..."
            PID=$(cat "$PID_FILE")
            rm $PID_FILE
            kill $PID
            exit 0
        else
            # start application and save its PID to file
            echo "Starting application..."
            showmethekey-gtk & 
            echo $! > $PID_FILE 
            exit 0
        fi
        ;;
    *)
        echo "Option not supported. Exiting..."
        exit 1
        ;;
esac
