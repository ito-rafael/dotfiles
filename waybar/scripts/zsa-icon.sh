#!/usr/bin/env bash

# check if there is any ZSA keyboard connected
if kontroll status | grep -q "No keyboard connected"; then
    # output nothing ("asks" Waybar to hide the image)
    echo ""
else
    # output the ZSA icon
    echo /home/rafael/.config/waybar/icon/zsa.png
fi
