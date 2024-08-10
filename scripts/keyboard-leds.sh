#!/usr/bin/env bash
#
# This script is meant to be used to turn on/off/dim the backlit RGB LEDs from specific keyboards. Currently, only two keyboards are supported:
#   - ZSA Moonlander MK1
#
# Prerequisites:
#   - ZSA's Keymapp (paru -S zsa-keymapp-bin)
#   - ZSA's Kontroll (paru -S zsa-kontroll-bin)
#
# Actions available:
#   - "on": turn on LEDs in their default colors.
#   - "off": turn off all LEDs.
#   - "dim": set LEDs in custom color and dim them.
#

# define parameters
COLOR="110000"

# get parameters
ACTION=$1

# get keyboard
STATUS=$(kontroll status | grep "No keyboard connected")
if [[ $STATUS ]]; then
    # keyboard not connected
    echo "Keyboard not connected. Exiting..."
    exit 0
else
    KEYBOARD=$(kontroll status | grep "Connected keyboard" | sed "s/Connected keyboard: *\s\(.*\)/\1/")
    echo "Found ZSA keyboard connected: $KEYBOARD"
    case "${KEYBOARD}" in
        # Moonlander keyboard connected
        "Moonlander MK1")
            # Moonlander Left
            L1=$(seq 1 5)
            L2=$(seq 8 12)
            L3=$(seq 15 19)
            L4=$(seq 25 26)
            LT="33"
            # Moonlander Right
            R1=$(seq 37 41)
            R2=$(seq 44 48)
            R3=$(seq 51 55)
            R4=""
            RT=$(seq 57 58)
            ;;
        *)
            echo "Keyboard not supported!"
            exit 0
            ;;
    esac
fi

case "${ACTION}" in
    "on")
        kontroll restore-rgb-leds
        exit 0
        ;;
    "off")
        kontroll set-rgb-all --color 000000
        exit 0
        ;;
    "dim")
        # turn off leds
        kontroll set-rgb-all --color 000000

        # them turn on in specific color
        LEFT="$L1 $L2 $L3 $L4 $LT"
        RIGHT="$R1 $R2 $R3 $R4 $RT"
        LEDS="$LEFT $RIGHT"
        
        for led in $LEDS;
        do
            kontroll set-rgb --led $led --color $COLOR
        done
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
