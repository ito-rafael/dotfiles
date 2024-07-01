#!/usr/bin/env bash
#
# This script is meant to be used with i3wm/Sway to identify the IP & port that ADB pair is running in order to stablish the pairing.
#

# try to discover IP & port of device ADB via mDNS
MDNS_OUTPUT=$(avahi-browse --all --ignore-local --resolve --terminate --parsable | grep adb-RQ8N400FVCP-bNfaUl | grep pairing | tail -1)
IP=$(echo $MDNS_OUTPUT | cut -d ";" -f8)
PORT=$(echo $MDNS_OUTPUT | cut -d ";" -f9)

# check if ADB pair is running
if [ -z "${MDNS_OUTPUT}" ]; then
    echo "Device not found! Exiting."
    exit 1
else
    echo "Device found: trying to pair with $IP:$PORT. Please enter the pairing code:"
    adb pair $IP:$PORT
fi
