#!/usr/bin/env bash

# check if gammastep is running in manual override mode (-O)
if pgrep -f "gammastep -O" > /dev/null; then
    # if in manual mode, read the value your script saved
    RAW_TEMP=$(cat /tmp/gamma_temp.tmp)
else
    # if in auto mode, calculate the temperature normally
    RAW_TEMP=$(gammastep -p 2>&1 | grep "Color temperature" | grep -o "[0-9]*")
fi

# divide temperature by 1000, format to 1 decimal place, and append 'K'
echo "$RAW_TEMP" | awk '{printf "%.1f\n", $1/1000}'
