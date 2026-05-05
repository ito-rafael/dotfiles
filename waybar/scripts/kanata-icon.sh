#!/usr/bin/env bash

# check if the systemd user service is active
if ! systemctl --user is-active --quiet kanata; then
    echo ""  # output nothing to hide the image
    exit 0
fi

# if active, output the path to the image
echo "/home/rafael/.config/waybar/icon/kanata.svg"
