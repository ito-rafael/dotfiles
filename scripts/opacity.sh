#!/usr/bin/env bash

#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") window value [-h]

where:
    -h, --help   show this help text
    -start       start transparency program (picom for i3wm, inactive-windows-transparency.sh for Sway)
    -reset       kill current process & reset opacity of all windows to 0.85
    -toggle      start if not running, kill it if running
    -window      target window, can be one of the options:
       specific ID (eg: 0x0400000f),
       \"current\",
       \"all\"
    value        opacity level, can be one of the four options:
       float number between 0 and 1.0
       \"dec\", for decreasing by 0.05
       \"inc\", for increasing by 0.05
       \"toggle\", for switching between 1.0 and 0.85
"

DEFAULT=0.85

# print help menu
if [[ $1 == '-h' || $1 == '--help' ]]; then
	printf "script to change opacity level of windows\n\n"
	echo "$usage"
	exit
#=================================================
# get session type (i3/sway/tty)
#=================================================
else
    case "${XDG_SESSION_TYPE}" in
        #========================
        "x11") 
        #========================
            PID=$(xdotool getwindowfocus)
            #------------------------
            # current window
            if [[ $1 == 'current' ]]; then
                if [[ $2 == 'dec' ]]; then
                    picom-trans -w $(PID) -5
                elif [[ $2 == 'inc' ]]; then
                    picom-trans -w $(PID) +5
                elif [[ $2 == 'toggle' ]]; then
                    # IF CURRENT == 1.0
                        picom-trans -w $(PID) $DEFAULT
                    # ELSE
                        picom-trans -w $(PID) 1.0
                else
                    # SAFE CHECK IF $2 IS BETWEEN 0 and 1.0
                    picom-trans -w $(PID) $2
                fi
            #------------------------
            # all windows
            # @TODO
            elif [[ $1 == 'all' ]]; then
                wmctrl -l | awk '{print $1}' | xargs -i picom-trans -w {} $2
            #------------------------
            # specific window
            # @TODO
            else
                picom-trans -w $1 $2
            #------------------------
            fi
            exit 0 ;;
        #========================
        "wayland")
        #========================
            #------------------------
            # start
            #------------------------
            #if [[ $1 == 'start' ]]; then
            ## check it inactive-windows-transparency (IWT) code is already running
            #    PID=$(pgrep -f inactive-windows-transparency)
            #    if [[ $PID ]]; then
            #        # if it's running, exit
            #        exit 0
            #    else
            #        /usr/share/sway-contrib/inactive-windows-transparency.py --opacity 0.85 &
            #    fi
            #------------------------
            # toggle
            #------------------------
            if [[ $1 == 'toggle' ]]; then
            # check it inactive-windows-transparency (IWT) code is already running
                PID=$(pgrep -f inactive-windows-transparency)
                if [[ $PID ]]; then
                    # it's running --> kill it
                    pkill -f inactive-windows-transparency
                    exit 0
                else
                    # it's not running --> start it
                    /usr/share/sway-contrib/inactive-windows-transparency.py --opacity 0.85 &
                fi
            fi
            #------------------------
            # reset
            #------------------------
            if [[ $1 == 'reset' ]]; then
                # kill current inactive-windows-transparency (IWT)
                pkill -f inactive-windows-transparency
                # then relaunch the process with the default value of 0.85
                /usr/share/sway-contrib/inactive-windows-transparency.py --opacity 0.85 &
            fi
            #------------------------
            # current window
            #------------------------
            if [[ $1 == 'current' ]]; then
                PID=$(swaymsg -t get_tree | jq -re '.. | select(type == "object") | select(.focused == true) | .pid')
                #------------------------
                # decrease by 5%
                if [[ $2 == 'dec' ]]; then
                    swaymsg [pid=$PID] opacity minus 0.05
                #------------------------
                # increase by 5%
                elif [[ $2 == 'inc' ]]; then
                    swaymsg [pid=$PID] opacity plus 0.05
                #------------------------
                # toggle between 0.85 and 1.0
                elif [[ $2 == 'toggle' ]]; then
                    # try to increase opacity in 0.01
                    swaymsg opacity plus 0.01
                    if [ $? -eq 0 ]; then
                        # if no error, it means opacity WAS NOT 1
                        swaymsg opacity 1.0
                    else
                        # if error, it means opacity WAS 1
                        swaymsg opacity $DEFAULT
                    fi
                #------------------------
                # set specific value
                else
                    # @TODO: SAFE CHECK IF $2 IS BETWEEN 0 and 1.0
                    swaymsg [pid=$PID] opacity $2
                #------------------------
                fi
            #------------------------
            # all windows
            #------------------------
            elif [[ $1 == 'all' ]]; then
                PID_ALL=$(swaymsg -t get_tree | jq -re '.. | select(type == "object") | .pid' | sed '/null/d')
                #------------------------
                # decrease by 5%
                if [[ $2 == 'dec' ]]; then
                    while IFS= read -r PID; do
                        swaymsg [pid=$PID] opacity minus 0.05
                    done <<< "$PID_ALL"
                #-----------------------
                # increase by 5%
                elif [[ $2 == 'inc' ]]; then
                    while IFS= read -r PID; do
                        swaymsg [pid=$PID] opacity plus 0.05
                    done <<< "$PID_ALL"
                #------------------------
                # toggle between 0.85 and 1.0
                elif [[ $2 == 'toggle' ]]; then
                    # try to increase opacity in 0.01
                    swaymsg opacity plus 0.01
                    if [ $? -eq 0 ]; then
                        # if no error, it means opacity WAS NOT 1
                        while IFS= read -r PID; do
                            swaymsg [pid=$PID] opacity 1.0
                        done <<< "$PID_ALL"
                    else
                        # if error, it means opacity WAS 1
                        while IFS= read -r PID; do
                            swaymsg [pid=$PID] opacity $DEFAULT
                        done <<< "$PID_ALL"
                    fi
                #------------------------
                # set specific value
                else
                    # @TODO: SAFE CHECK IF $2 IS BETWEEN 0 and 1.0
                    while IFS= read -r PID; do
                        swaymsg [pid=$PID] opacity $2
                    done <<< "$PID_ALL"
                #------------------------
                fi
            #------------------------
            fi
            exit 0
            ;;
        #========================
        "tty") exit 0 ;;
        #========================
        *)     exit 0 ;;
        #========================
    esac
fi

#=================================================




