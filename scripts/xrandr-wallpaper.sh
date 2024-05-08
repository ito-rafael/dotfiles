#!/usr/bin/env bash

# get connected outputs manually
#PRIMARY=HDMI1
#SECONDARY=VGA1
#TERTIARY=HDMI3

# get connected outputs
PRIMARY=$(xrandr | grep ' connected' | awk '{print $1}' | head -n1 | tail -n1)
SECONDARY=$(xrandr | grep ' connected' | awk '{print $1}' | head -n2 | tail -n1)
TERTIARY=$(xrandr | grep ' connected' | awk '{print $1}' | head -n3 | tail -n1)

# delay
sleep 1

# configure outputs
xrandr \
    --output $PRIMARY   --mode 1920x1080 --rate 60.00 --brightness 1 --pos 0x0 --primary \
    --output $SECONDARY --mode 1920x1080 --rate 60.00 --brightness 1 --pos -1920x0 --rotate normal \
    --output $TERTIARY  --mode 1920x1080 --rate 60.00 --brightness 1 --pos 1920x0 --rotate right

# set wallpapers
feh \
    --bg-scale ~/.config/wallpaper/london.jpg \
    --bg-scale ~/.config/wallpaper/london.jpg \
    --bg-scale ~/.config/wallpaper/nasa.png
