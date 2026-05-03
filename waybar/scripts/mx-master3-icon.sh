#!/usr/bin/env bash

TARGET_MODEL="MX Master 3"
DEVICE=""

# find the device path
for dev in $(upower -e); do
    if upower -i "$dev" | grep -iq "model:.*$TARGET_MODEL"; then
        DEVICE="$dev"
        break
    fi
done

# check if the mouse is connected
if [ -z "$DEVICE" ]; then
    echo ""  # output nothing to hide the image module
    exit 0
fi

# if active, display the icon
echo /home/rafael/.config/waybar/icon/mx-master3.png
