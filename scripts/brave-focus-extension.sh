#!/usr/bin/env bash

# delay
sleep 0.5

# get current window geometry in Sway (x, y, width)
read -r WINDOW_X WINDOW_Y WINDOW_WIDTH <<< $(swaymsg -t get_tree | jq -r '.. | objects | select(.focused? == true) | .rect | "\(.x) \(.y) \(.width)"')

# calculate target coordinates
# (250 px from right edge, 200 px from top)
TARGET_X=$((WINDOW_X + WINDOW_WIDTH - 250))
TARGET_Y=$((WINDOW_Y + 200))

echo $WINDOW_X $WINDOW_Y $WINDOW_WIDTH > ~/.config/scripts/test
echo $TARGET_X $TARGET_Y >> ~/.config/scripts/test

# move the mouse cursor and left click
swaymsg seat seat0 cursor set "$TARGET_X" "$TARGET_Y"
sleep 0.05
swaymsg exec ydotool click 0xC0
