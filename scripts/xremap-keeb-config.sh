#!/usr/bin/env bash

'''
This script is meant to be run on Sway. It starts xremap configuring it to
listen specific devices. After that, it configures the model, layout, and
variant, of these keyboards. The keyboards supported so far are:

keyboards:
  - ZSA Moonlander
  - ZSA Planck EZ
  - laptop native keyboards
'''

# start xremap
xremap \
    --device "ZSA Technology Labs Moonlander Mark I" \
    --device "KMonad INKL output" \
    --device "AT Translated Set 2 keyboard" \
    --watch $HOME/.config/xremap/config.yml &

# delay to wait device assignment
sleep 2

# get xremap device identifier
XREMAP_DEVICE=$(swaymsg -t get_inputs | jq -re '.. | select(type == "object") | select(.type == "keyboard") | select(.name | startswith("xremap")) | .identifier')
echo "xremap device identifier: $XREMAP_DEVICE"

# configure keyboard within sway
swaymsg input $XREMAP_DEVICE xkb_model "pc105"
swaymsg input $XREMAP_DEVICE xkb_layout "us"
swaymsg input $XREMAP_DEVICE xkb_variant "intl"
echo "xremap input device configured!"
