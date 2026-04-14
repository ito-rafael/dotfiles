#!/usr/bin/env bash

VPN=$1
BG_COLOR=$2
FG_COLOR=f0f0f0
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
    echo "%{B#$BG_COLOR}%{F#$FG_COLOR} $TEXT %{B-}%{F-}"
else
    echo ""
fi
