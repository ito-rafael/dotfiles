#!/bin/bash
#-------------------------------------------------
# - create a help menu
# - use getopts to configure IP, NETMASK & TIMEOUT
#-------------------------------------------------
# configuration
IP="143.106.45.163"
NETMASK="32"
TIMEOUT="56"
#-------------------------------------------------
# wait any host within the range to be up
while [ "$(fping -ag $IP/$NETMASK)" == "" ]; do 
    echo "[$(date +%H:%M:%S)] waiting..."
    sleep $TIMEOUT
done
#-------------------------------------------------
# get first host up within the range given
HOST="$(fping -ag $IP/$NETMASK | head -n1)" 
echo "[$(date +%H:%M:%S)] host $IP up"
#-------------------------------------------------
# send desktop notification
notify-send \
    --expire-time=0 \
    --urgency=critical \
    --icon='/usr/share/icons/Adwaita/32x32/status/dialog-warning-symbolic.symbolic.png' \
    'Host up!' \
    $HOST
echo "[$(date +%H:%M:%S)] notification sent!"
#-------------------------------------------------
