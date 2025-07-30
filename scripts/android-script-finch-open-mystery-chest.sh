#!/usr/bin/env bash
#
# description:
#   script to open mystery chest from journeys in Finch using scrcpy to mirror the phone and ydotool to perform the clicks.
#
# prerequisites:
#   - adb
#   - scrcpy
#   - ydotool
#
# Finch status:
#   - Home screen

LEFT_CLICK=0xC0
DELAY=2.0

sleep $DELAY

for NUMBER in {1..100..1}
do
    # Open mystery chest!
    ydotool mousemove --absolute 960 530
    ydotool click $LEFT_CLICK
    sleep $DELAY

    # Choose a gift box to claim your reward!
    ydotool mousemove --absolute 960 920
    ydotool click $LEFT_CLICK
    sleep $DELAY

    # Done
    ydotool mousemove --absolute 960 959
    ydotool click $LEFT_CLICK
    sleep $DELAY
done
