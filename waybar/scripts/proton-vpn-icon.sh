#!/usr/bin/env bash

# fetch status cleaning ANSI colors and carriage returns
STATUS=$(protonvpn status 2>/dev/null | sed $'s/\033\\[[0-9;]*m//g' | tr -d '\r')

# check if Proton VPN is connected
if echo "$STATUS" | grep -qi "Status: *Connected"; then
    # it's connected! output nothing so the image module completely hides.
    echo ""
else
    # it's disconnected! output the Proton VPN icon
    echo "/home/rafael/.config/waybar/icon/proton-vpn-disconnected.svg"
fi
