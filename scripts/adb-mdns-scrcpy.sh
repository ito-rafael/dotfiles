#!/usr/bin/env bash
#
# This script is meant to be used with i3wm to mirror a device (eg: phone, smartwatch) screen on the desktop.
#
# Prerequisites:
#   - device already paired with the desktop: "adb pair IP:PORT".
#   - "debug wireless" activated on the device (Developer options).
#   - scrcpy: tool to mirror device screen (https://github.com/Genymobile/scrcpy).
#   - Avahi: tool to discover the IP & port of the device (wireless ADB) via mDNS.
#
# How it works:
#   1. Check if =scrcpy= scratchpad exists. If it does, show it and exit.
#   2. If not, try to find the ADB IP & port of the device.
#   3. If it finds, start =scrcpy= and display it. If not, exit.
#

# calc size of window (90% of full height)
# examples:
#   - for 1920x1080: height = 972
#   - for 3840x2160: height = 1944
RESOLUTION=$(swaymsg -t get_outputs | jq '.[] | select(.focused==true).current_mode')
RES_WIDTH=$(echo $RESOLUTION | jq '.width')
RES_HEIGHT=$(echo $RESOLUTION | jq '.height')
WIN_HEIGHT=$(echo "0.9 * $RES_HEIGHT" | bc)

# check if scratchpad is already active
SCRATCHPAD=$(swaymsg -t get_tree | jq -re '.. | select(type == "object") | select(.app_id == "scrcpy" and .name == "dropdown_scrcpy")')

# display scratchpad if it's active, or try to launch if it isn't
if [[ $SCRATCHPAD ]]; then
    echo "Scratchpad found! Displaying it..."
    swaymsg '[app_id="scrcpy" title="dropdown_scrcpy"] scratchpad show'
    exit 0
else
    # try to discover IP & port of device ADB via mDNS
    echo "Scratchpad not found! Searching for ADB IP & port on device..."
    MDNS_OUTPUT=$(avahi-browse --all --ignore-local --resolve --terminate --parsable | grep adb-RQ8N400FVCP-bNfaUl | grep v=ADB_SECURE_SERVICE_VERSION | tail -1)
    IP=$(echo $MDNS_OUTPUT | cut -d ";" -f8)
    PORT=$(echo $MDNS_OUTPUT | cut -d ";" -f9)

    # check if ADB is running
    if [ -z "${MDNS_OUTPUT}" ]; then
        echo "Device not found! Exiting."
        exit 1
    else
        echo "Device found: trying to connect to $IP:$PORT."
        adb connect $IP:$PORT
        scrcpy -s $IP:$PORT --window-title="dropdown_scrcpy" >& /dev/null &

        # wait for scrcpy window to be launched
        SCRATCHPAD=$(swaymsg -t get_tree | jq -re '.. | select(type == "object") | select(.app_id == "scrcpy" and .name == "dropdown_scrcpy")')
        if [ -z $SCRATCHPAD ]; then
            echo "Waiting scratchpad to be launched."
            while [[ $SCRATCHPAD ]]; do
                sleep 0.2
                echo "..."
                SCRATCHPAD=$(swaymsg -t get_tree | jq -re '.. | select(type == "object") | select(.app_id == "scrcpy" and .name == "dropdown_scrcpy")')
            done
        fi

        # display scratchpad
        sleep 2
        swaymsg '[app_id="scrcpy" title="dropdown_scrcpy"] scratchpad show'
        exit 0
    fi
fi
