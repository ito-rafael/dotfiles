#!/usr/bin/env bash
#
# description:
#   script to delete fake journeys in Finch using scrcpy to mirror the phone and ydotool to perform the clicks.
#
# prerequisites:
#   - adb
#   - scrcpy
#   - ydotool
#
# Finch status:
#   - Home screen
#   - goals to be completed listed earlier

LEFT_CLICK=0xC0
DELAY=1.5

sleep $DELAY
    
for NUMBER in {1..100..1}
do
    # check icon
    ydotool mousemove --absolute 1134 809
    ydotool click $LEFT_CLICK
    sleep $DELAY
    
    # Done
    ydotool mousemove --absolute 960 1034
    ydotool click $LEFT_CLICK
    sleep $DELAY
done
