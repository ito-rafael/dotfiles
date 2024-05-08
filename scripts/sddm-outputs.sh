#!/usr/bin/env bash

# - this script is used to display SDDM greeter in one output only.
# - its content should be put in: /usr/share/sddm/scripts/Xsetup.

# get connected outputs manually
#PRIMARY=HDMI1
#SECONDARY=VGA1
#TERTIARY=HDMI3

# get connected outputs
PRIMARY=$(xrandr | grep ' connected' | awk '{print $1}' | head -n1 | tail -n1)
SECONDARY=$(xrandr | grep ' connected' | awk '{print $1}' | head -n2 | tail -n1)
TERTIARY=$(xrandr | grep ' connected' | awk '{print $1}' | head -n3 | tail -n1)

# display SDDM only in primary output
xrandr --output $PRIMARY --mode 1920x1080 --rate 60.00 --brightness 1 --pos 0x0 --primary
xrandr --output $SECONDARY --off
xrandr --output $TERTIARY --off
