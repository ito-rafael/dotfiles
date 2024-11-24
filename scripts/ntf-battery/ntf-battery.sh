#!/usr/bin/env bash
# send notifications when battery is low
while true; do
    battery_level=$(acpi -b | tail -n1 | grep -oP '[0-9]+(?=%)')
    battery_state=$(acpi -b | tail -n1 | grep -oP '(?<=: ).*(?=, [0-9]{1,3}%)')
    # check if the host has a battery (eg: it's a laptop)
    if [ "$battery_state" == "" ]; then
        exit 1
    fi
    #echo $battery_level
    #echo $battery_state
    if [ $battery_state == "Discharging" ]; then
        #---------------------------------------
        # Battery Half Charged: 50%
        #---------------------------------------
        if [ $battery_level -eq 50 ]; then
            notify-send \
                --expire-time=5000 \
                --urgency=normal \
                --icon='~/config/scripts/ntf_battery/half.png' \
                "Battery Discharging" \
                "Level: ${battery_level}%"
            paplay /usr/share/sounds/freedesktop/stereo/dialog-information.oga
        #---------------------------------------
        # Battery Low: 15%
        #---------------------------------------
        elif [ $battery_level -eq 15 ]; then
            notify-send \
                --expire-time=0 \
                --urgency=CRITICAL \
                --icon='~/config/scripts/ntf_battery/low.png' \
                "Battery Low" \
                "Level: ${battery_level}%"
            paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga
        #---------------------------------------
        # Battery Critical: < 5%
        #---------------------------------------
        elif [ $battery_level -le 5 ]; then
            # adjust volume if it is less than 25%
            default_sink=$(pactl info | grep "Default Sink"| sed 's/Default Sink: //')
            volume=$(pactl get-sink-volume $default_sink | grep -Eo '[0-9]{1,2}%' | grep -Eo '[0-9]{1,2}' | head -n1)
            #volume=$(pactl list sinks | grep '^[[:space:]]Volume:' | grep -Eo '[0-9]{1,2}%' | grep -Eo '[0-9]{1,2}' | head -n1)
            if [ $volume -le 25 ]; then
                pactl list sinks | grep 'Sink #' | grep -o '[0-9]*' | xargs -i pactl set-sink-volume {} 50% && pkill -RTMIN+1 i3blocks
            fi
            # send notification
            notify-send \
                --expire-time=0 \
                --urgency=CRITICAL \
                --icon='~/config/scripts/ntf_battery/critical.png' \
                "Battery Critical" \
                "Level: ${battery_level}%"
            # play sound until battery is charging
            while [ $battery_state != "Charging" ]; do

                battery_state=$(acpi -b | tail -n1 | grep -oP '(?<=: ).*(?=, [0-9]{1,3}%)')
                paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga
                sleep 10
            done
        fi
        #---------------------------------------
    fi
    sleep 30
done
