#!/usr/bin/env bash

# fetch the current layer number using kontroll
layer=$(kontroll status 2>/dev/null | grep 'layer' | awk '{print $NF}')

# safety check: If Keymapp is closed or the keyboard is unplugged, $layer will be empty
if [ -z "$layer" ]; then
    #printf '{"text": "N/A", "class": "disconnected"}\n'
    echo ""  # output nothing to hide the module in Waybar
    exit 0
fi

# map the layer numbers to your preferred names
case "$layer" in
    0)  name="col"  ;;  # colemak"
    1)  name="num"  ;;  # number"
    2)  name="sym"  ;;  # symbol"
    3)  name="obs"  ;;  # obs"
    4)  name="obn"  ;;  # obs-num"
    5)  name="wm"   ;;  # window-manager"
    6)  name="nav"  ;;  # navigation"
    7)  name="med"  ;;  # media"
    8)  name="lum"  ;;  # luminosity"
    9)  name="rat"  ;;  # mouse"
    10) name="misc" ;;  # misc"           
    11) name="out1" ;;  # out1"           
    12) name="out2" ;;  # out2"           
    13) name="out3" ;;  # out3"           
    14) name="yt"   ;;  # youtube-speed"
    15) name="fn1"  ;;  # function-keys-1"
    16) name="fn2"  ;;  # function-keys-2"
    *) name="Layer $layer" ;; # fallback for unmapped layers
esac

# print the result as a Waybar-compatible JSON object
printf '{"text": "%s", "class": "layer-%s"}\n' "$name" "$layer"
