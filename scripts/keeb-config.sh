#!/usr/bin/env bash

#=================================================
# get session type (i3/sway/tty)
#=================================================

echo $XDG_SESSION_TYPE
case "${XDG_SESSION_TYPE}" in
    "x11") 
        echo ================ X11 ================
        xmodmap $HOME/.Xmodmap
        exit 0 ;;
    "wayland")
        echo ================ WAY ================
        # try to get xremap device identifier
        XREMAP_DEVICE=$(swaymsg -t get_inputs | jq -re '.. | select(type == "object") | select(.type == "keyboard") | select(.name | startswith("xremap")) | .identifier')
        
        # check if xremap device exists
        if [[ $XREMAP_DEVICE == "" ]]; then
            echo "Error: couldn't find xremap device!"
            exit 1
        else
            echo "xremap device identifier: $XREMAP_DEVICE"
        
            # configure keyboard within sway
            swaymsg input $XREMAP_DEVICE xkb_model "pc105"
            swaymsg input $XREMAP_DEVICE xkb_layout "us"
            swaymsg input $XREMAP_DEVICE xkb_variant "intl"
            echo "xremap input device configured!"
            exit 0
        fi
        ;;
    "tty") 
        echo ================ TTY ================
        exit 0 ;;
    *)     
        echo ================ STAR ================
        exit 0 ;;
esac
