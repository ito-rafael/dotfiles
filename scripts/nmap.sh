#!/usr/bin/env bash

#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") [--interface] [-h]

where:
    -h, --help        show this help text
    -i, --interface   interface to perform nmap, can be one of the options:
      \"eth\"             Ethernet device
      \"wlp\"             wireless device
"
#------------------------
# print help menu
if [[ $1 == '-h' || $1 == '--help' ]]; then
	printf "script to create, show, detach or destroy temporary scratchpad\n\n"
	echo "$usage"
	exit 0
fi

#=================================================
# get interface
INTERFACE=$1
if [ $INTERFACE ]; then
    case "${INTERFACE}" in
        # grep -v /: removes directories
        # grep -v "^$": removes empty lines
        "eth")
            DEVICE=$(ls /sys/class/net/e*/device/net | grep -v / | grep -v "^$" | head -n1)
            ;;
        "wlp")
            DEVICE=$(ls /sys/class/ieee80211/*/device/net | grep -v / | grep -v "^$" | head -n1)
            ;;
        *)
            echo "Interface not supported. Exiting."
            exit 1
            ;;
    esac
else
    # if "--interface" was not provided, get the first on from "net" class
    DEVICE=$(ls /sys/class/net/*/device/net | grep -v / | grep -v "^$" | head -n1)
fi

# check if device was found correctly
if [[ -z ${DEVICE} ]]; then
    echo "Device not found. Exiting."
    exit 1
fi
echo "Device selected: $DEVICE"

#=================================================

# get subnetwork from gateway
SUBNET=$(ip -json route | jq  -re '.[] | select(.dev == "'$DEVICE'").dst' | tail -n1)

# launch nmap command
nmap -sn $SUBNET
