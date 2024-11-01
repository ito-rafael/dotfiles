#!/usr/bin/env bash
#
# This script is meant to be used with i3wm (Sway has this feature by default) to focus an adjacent window {left,down,up,right} and centralize the mouse cursor in this new focused window.
#
# Prerequisites:
#   - xdotool
#
# Source:
#   https://github.com/i3/i3/issues/2971

# parse direction parameter
DIRECTION=$1

# focus adjacent window
i3-msg focus $DIRECTION

# get window ID
WINDOW=$(xdotool getwindowfocus)

# this brings in variables WIDTH and HEIGHT
eval `xdotool getwindowgeometry --shell $WINDOW`

# calculate new cursor position
TX=$(expr $WIDTH / 2)
TY=$(expr $HEIGHT / 2)

# move cursor to the center of window
xdotool mousemove -window $WINDOW $TX $TY
