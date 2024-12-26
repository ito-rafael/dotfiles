#!/usr/bin/env bash

# get variables
DEVICE=$(brightnessctl --list | grep kbd_backlight | cut -d "'" -f2)
#CURRENT_BRIGHTNESS=$(cat /sys/class/leds/platform::kbd_backlight/brightness)
#MAX_BRIGHTNESS=$(cat /sys/class/leds/platform::kbd_backlight/max_brightness)
CURRENT_BRIGHTNESS=$(brightnessctl --device=$DEVICE info | grep "Current brightness" | cut -d " " -f3)
MAX_BRIGHTNESS=$(brightnessctl --device=$DEVICE info | grep "Max brightness" | cut -d " " -f3)

#=================================================
# help menu and usage message
#=================================================

usage="$(basename "$0") value [-h]

where:
    -h, --help   show this help text
    value        brightness level, can be one of the four options:
       int, number between 0 and $MAX_BRIGHTNESS
       \"dec\", for decreasing by 1
       \"inc\", for increasing by 1
       \"toggle\", for turning it on/off (levels 2 or 0) 
       \"cycle\", for cycling among 0, 1 and 2
"
#------------------------
# print help menu
if [[ $1 == '-h' || $1 == '--help' ]]; then
	printf "script to change keyboard brightness of laptops\n\n"
	echo "$usage"
	exit
#------------------------
# parse arguments
else
    VALUE=$1
    case "${VALUE}" in
        #------------------------
        "dec")
            if [ $CURRENT_BRIGHTNESS -gt 0 ]; then
                NEW_VALUE=$(echo $CURRENT_BRIGHTNESS - 1 | bc)
                echo "Previous backlit level was $CURRENT_BRIGHTNESS. Setting it to $NEW_VALUE"
                brightnessctl --device=$DEVICE set $NEW_VALUE
            fi
            ;;
        #------------------------
        "inc")
            if [ $CURRENT_BRIGHTNESS -lt $MAX_BRIGHTNESS ]; then
                NEW_VALUE=$(echo $CURRENT_BRIGHTNESS + 1 | bc)
                echo "Previous backlit level was $CURRENT_BRIGHTNESS. Setting it to $NEW_VALUE"
                brightnessctl --device=$DEVICE set $NEW_VALUE
            fi
            ;;
        #------------------------
        "toggle")
            if [ $CURRENT_BRIGHTNESS -eq 0 ]; then
                # turn on
                TEMP_FILE="/run/user/1000/brightnessctl/leds/"$DEVICE
                if [ -f $TEMP_FILE ]; then
                    # if temp file exists, restore level from it
                    brightnessctl --device=$DEVICE --restore
                else
                    # if temp file does not exist, set level to minimum
                    brightnessctl --device=$DEVICE set 1
                fi
            else
                # turn off
                brightnessctl --device=$DEVICE --save set 0
            fi
            ;;
        #------------------------
        "cycle")
            if [ $CURRENT_BRIGHTNESS -eq $MAX_BRIGHTNESS ]; then
                # if max, turn it off
                brightnessctl --device=$DEVICE set 0
            else
                # else, increment
                NEW_VALUE=$(echo $CURRENT_BRIGHTNESS + 1 | bc)
                echo "Previous backlit level was $CURRENT_BRIGHTNESS. Setting it to $NEW_VALUE"
                brightnessctl --device=$DEVICE set $NEW_VALUE
            fi
            ;;
        #------------------------
        *)
            if [ $VALUE -ge 0 ] && [ $VALUE -le $MAX_BRIGHTNESS ]; then
                brightnessctl --device=$DEVICE set $VALUE
            else
                echo "Invalid value. Exiting."
                exit 1
            fi
            ;;
    esac
fi
