#!/usr/bin/env bash
#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") window [-h]

where:
    -h, --help   show this help text
    -window,     target window, can be one of the options:
       specific ID (eg: 0x0400000f),
       \"current\",
       \"all\""
#------------------------
# print help menu
if [[ $1 == '-h' || $1 == '--help' ]]; then
	printf "script to change opacity level of windows\n\n"
	echo "$usage"
	exit
#------------------------
# current window
elif [[ $1 == 'current' ]]; then
    picom-trans -w $(xdotool getwindowfocus) $2
#------------------------
# all windows
elif [[ $1 == 'all' ]]; then
    wmctrl -l | awk '{print $1}' | xargs -i picom-trans -w {} $2
#------------------------
# specific window
else
    picom-trans -w $1 $2
#------------------------
fi
