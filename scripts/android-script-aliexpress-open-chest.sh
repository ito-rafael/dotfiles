#!/usr/bin/env bash
#
# description:
#   script to open chests in AliExpress using scrcpy to mirror the phone and ydotool to perform the clicks.
#
# prerequisites:
#   - adb
#   - scrcpy
#   - ydotool
#

LEFT_CLICK=0xC0
DELAY=2.0

sleep $DELAY

# move cursor into position
#ydotool mousemove -x 9999 -y 9999
#ydotool mousemove -x -480 -y -180

for NUMBER in {1..100..1}
do
    # open chest
    ydotool mousemove -x 9999 -y 9999
    #ydotool mousemove -x -480 -y -180  # central scratchpad
    ydotool mousemove -x -240 -y -170  # split window on the right
    ydotool click $LEFT_CLICK
    sleep $DELAY

    # claim prize
    ydotool mousemove -x 9999 -y 9999
    #ydotool mousemove -x -480 -y -180  # central scratchpad
    ydotool mousemove -x -240 -y -170  # split window on the right
    ydotool click $LEFT_CLICK
    sleep $DELAY
done
