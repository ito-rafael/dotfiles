#!/usr/bin/env bash
#
# This script is meant to be used with i3wm (Sway has this feature by default) to centralize the mouse cursor when navigating among windows.
#
# Prerequisites:
#   - xdotool
#
# Source:
#   https://github.com/i3/i3/issues/2971

# get window ID
WINDOW=$(xdotool getwindowfocus)

# this brings in variables WIDTH and HEIGHT
eval `xdotool getwindowgeometry --shell $WINDOW`

# calculate new cursor position
TX=$(expr $WIDTH / 2)
TY=$(expr $HEIGHT / 2)

# move cursor to the center of window
xdotool mousemove -window $WINDOW $TX $TY
