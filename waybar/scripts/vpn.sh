#!/usr/bin/env bash

VPN=$1
PID_FILE='/tmp/vpn_'$VPN'_pid.tmp'

# get text to be displayed
case "${VPN}" in
    "lcn")
        TEXT="La Casa Nostra"
        ;;
    "unicamp")
        TEXT="Unicamp"
        ;;
    "lbic")
        TEXT="LBiC"
        ;;
    "samsung")
        TEXT="Samsung"
        ;;
    *)
        ;;
esac

if [ -f $PID_FILE ]; then
    printf '{"text": " '"${TEXT}"' ", "class": "enabled"}';
else
	printf '{"text": ""}';
fi
