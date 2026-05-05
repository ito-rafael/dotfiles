#!/usr/bin/env bash
PROTON_FILE="/tmp/proton-vpn-status.tmp"
PROTON_STATUS=$(cat "$PROTON_FILE" 2>/dev/null)

case "$PROTON_STATUS" in
connected)
    # fetch status cleaning ANSI colors and carriage returns
    STATUS=$(protonvpn status 2>/dev/null | sed $'s/\033\\[[0-9;]*m//g' | tr -d '\r')

    # extract server name
    SERVER=$(echo "$STATUS" | grep -i "Server:" | awk '{print $2}')

    # extract the country code and explicitly convert it to lowercase
    CC=$(echo "$SERVER" | cut -d'-' -f1 | tr -dc 'a-zA-Z' | tr '[:upper:]' '[:lower:]')

    # construct the path to the lipis flag icon
    FLAG_FILE="/home/rafael/.config/waybar/icon/flag-icons/flags/4x3/${CC}.svg"

    # output the flag if it exists, otherwise fallback to the default connected icon
    if [ -n "$CC" ] && [ -f "$FLAG_FILE" ]; then
        echo "$FLAG_FILE"
    else
        echo "/home/rafael/.config/waybar/icon/proton-vpn.svg"
    fi
    ;;
disconnected)
    echo "/home/rafael/.config/waybar/icon/proton-vpn-disconnected.svg"
    ;;
connecting)
    echo "/home/rafael/.config/waybar/icon/proton-vpn-connecting.svg"
    ;;
disconnecting)
    echo "/home/rafael/.config/waybar/icon/proton-vpn-disconnecting.svg"
    ;;
*)
    echo "/home/rafael/.config/waybar/icon/blank.svg"
    ;;
esac
