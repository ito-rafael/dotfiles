#!/usr/bin/env bash

# fetch current temperature
if pgrep -f "gammastep -O" > /dev/null; then
    RAW_TEMP=$(cat /tmp/gamma_temp.tmp)
else
    RAW_TEMP=$(gammastep -p 2>&1 | grep "Color temperature" | grep -o "[0-9]*")
fi

# safety check (if gammastep fail, output nothing to hide the icon)
if [ -z "$RAW_TEMP" ]; then
    echo ""
    exit 0
fi

# map to 10 image levels
if [ "$RAW_TEMP" -ge 6499 ]; then
    IMAGE="6500.png"
elif [ "$RAW_TEMP" -ge 5999 ]; then
    IMAGE="6000.png"
elif [ "$RAW_TEMP" -ge 5499 ]; then
    IMAGE="5500.png"
elif [ "$RAW_TEMP" -ge 4999 ]; then
    IMAGE="5000.png"
elif [ "$RAW_TEMP" -ge 4499 ]; then
    IMAGE="4500.png"
elif [ "$RAW_TEMP" -ge 3999 ]; then
    IMAGE="4000.png"
elif [ "$RAW_TEMP" -ge 3499 ]; then
    IMAGE="3500.png"
elif [ "$RAW_TEMP" -ge 2999 ]; then
    IMAGE="3000.png"
else
    # anything below 2999K gets the 2000K image (lowest level)
    IMAGE="2500.png"
fi

# output the image path
echo "/home/rafael/.config/waybar/icon/screen-color-temperature/$IMAGE"
