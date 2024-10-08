#!/usr/bin/env bash
#
# This script is used to connect/disconnect VPNs.
#
# Installation:
#   Arch:
#     - sudo pacman -S yad
#
#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") destination action [-h]

where:
    -h, --help      show this help text
    destination     supported options so far includes: \"lcn\", \"unicamp\", \"lbic\", \"samsung\"
    action          action to be performed, can be one of the three options:
      \"connect\"       connects to the VPN
      \"disconnect\"    disconnects from the VPN
      \"toggle\"        toggle the connection (connect/disconnect)
"
#=================================================
# print help menu
if [[ $1 == '-h' || $1 == '--help' || $1 == '' ]]; then
    printf "Script to connect to or disconnect from VPNs.\n\n"
    echo "$usage"
    exit
fi

#=================================================
# parse parameters
VPN=$1
ACTION=$2
PID_FILE='/tmp/vpn_'${VPN}'_pid.tmp'
LAUNCHER=${XDG_CONFIG_HOME}'/vpn/'${VPN}'/vpn-'${VPN}'.sh'
IMAGE=${XDG_CONFIG_HOME}'/vpn/'${VPN}'/icon/icon.png'

# get text to be displayed
case "${VPN}" in
    "lcn")
        VPN_NAME="\"La Casa Nostra\""
        ;;
    "unicamp")
        VPN_NAME="Unicamp"
        ;;
    "lbic")
        VPN_NAME="LBiC"
        ;;
    "samsung")
        VPN_NAME="Samsung"
        ;;
    *)
        ;;
esac
# prepare message for dialog
TEXT="  VPN $VPN_NAME\n  Enter password:"

# check if VPN is supported
if ! [[ $VPN == 'lcn' || $VPN == 'unicamp' || $VPN == 'lbic' || $VPN == 'samsung' ]]; then
    echo VPN option not supported. Exiting...
    exit 1
fi

# check if action is supported
if ! [[ $ACTION == 'connect' || $ACTION == 'disconnect' || $ACTION == 'toggle' ]]; then
    echo Action option not supported. Exiting...
    exit 1
fi

# get password with dialog
PASSWORD="$(yad \
    --center \
    --entry \
    --hide-text \
    --text="$TEXT" \
    --title="Authentication required" \
    --licon=/usr/share/icons/Papirus-Dark/32x32/status/dialog-password.svg \
    --image=$IMAGE \
    )"

# check password
if echo $PASSWORD | su - $USER -c true; then
    # password is correct, ignoring...
    true
else
    # password is wrong, exiting...
    yad \
        --center \
        --button=yad-ok \
        --buttons-layout=center \
        --text="Password incorrect." \
        --image=/usr/share/icons/Papirus-Dark/32x32/status/dialog-error.svg \
    exit 1
fi

#=================================================
# check option selected
case "${ACTION}" in
    "connect")
        # check if it's already running
        if [ -f $PID_FILE ]; then
            # ignore
            echo "PID file already exists. Exiting..."
            exit 0
        else
            # start application and save its PID to file (this is done inside $LAUNCHER)
            echo "Starting application..."
            echo $PASSWORD | sudo -S $LAUNCHER &
            exit 0
        fi
        ;;
    "disconnect")
        # check if it's already running
        if [ -f $PID_FILE ]; then
            # stop and remove PID file
            echo "Stopping application..."
            PID=$(cat "$PID_FILE")
            echo $PASSWORD | sudo -S rm $PID_FILE
            echo $PASSWORD | sudo -S kill $PID
            exit 0
        else
            # ignore
            echo "PID file does not exist. Exiting..."
            exit 0
        fi
        ;;
    "toggle")
        # check if it's already running
        if [ -f $PID_FILE ]; then
            # stop and remove PID file
            echo "Stopping application..."
            PID=$(cat "$PID_FILE")
            echo $PASSWORD | sudo -S sudo rm $PID_FILE
            echo $PASSWORD | sudo -S sudo kill $PID
            exit 0
        else
            # start application and save its PID to file (this is done inside $LAUNCHER)
            echo "Starting application..."
            echo $PASSWORD | sudo -S $LAUNCHER &
            exit 0
        fi
        ;;
    *)
        echo "Option not supported. Exiting..."
        exit 1
        ;;
esac
