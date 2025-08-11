#!/usr/bin/env bash

# kill xremap
killall xremap

# start xremap
xremap \
    --mouse \
    --device "ZSA Technology Labs Moonlander Mark I" \
    --device "ZSA Technology Labs Planck EZ Glow" \
    --device "KMonad INKL output" \
    --device "AT Translated Set 2 keyboard" \
    --watch $HOME/.config/xremap/config.yml &

# delay to wait device assignment
sleep 2

#=================================================
# get session type (i3/sway/tty)
#=================================================

case "${XDG_SESSION_TYPE}" in
    "x11") 
        xmodmap $HOME/.Xmodmap
        exit 0 ;;
    "wayland")
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
    "tty") exit 0 ;;
    *)     exit 0 ;;
esac
