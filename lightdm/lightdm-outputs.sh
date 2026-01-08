#!/bin/sh

# - this script is used to display LightDM greeter in one output only.
# - its content should be put in: /etc/lightdm/lightdm-outputs.sh.

# get connected outputs manually
# LBiC
PRIMARY=HDMI-A-1
SECONDARY=DP-1
TERTIARY=DVI-I-1

# get connected outputs
#PRIMARY=$(xrandr | grep ' connected' | awk '{print $1}' | head -n1 | tail -n1)
#SECONDARY=$(xrandr | grep ' connected' | awk '{print $1}' | head -n2 | tail -n1)
#TERTIARY=$(xrandr | grep ' connected' | awk '{print $1}' | head -n3 | tail -n1)

# display SDDM only in primary output
xrandr --output $PRIMARY --mode 1920x1080 --rate 60.00 --brightness 1 --pos 0x0 --primary &
xrandr --output $SECONDARY --off &
xrandr --output $TERTIARY --off &
exit 0
