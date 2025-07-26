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
#   - real journeys temporarily archived
#   - Home screen

LEFT_CLICK=0xC0
DELAY=1.5

sleep $DELAY
    
for NUMBER in {1..100..1}
do
    # hamburger icon
    ydotool mousemove --absolute 757 148
    ydotool click $LEFT_CLICK
    sleep $DELAY
    
    # My Journeys
    ydotool mousemove --absolute 849 389
    ydotool click $LEFT_CLICK
    sleep $DELAY

    # scroll down (3x PageDown)
    for i in {0..2..1}
    do
        ydotool key 109:1 109:0
        sleep 0.5
    done
    
    # click on first journey
    ydotool mousemove --absolute 962 336
    ydotool click $LEFT_CLICK
    sleep $DELAY
    
    # three dots
    ydotool mousemove --absolute 1154 149
    ydotool click $LEFT_CLICK
    sleep $DELAY
    
    # Delete Journey
    ydotool mousemove --absolute 809 941
    ydotool click $LEFT_CLICK
    sleep $DELAY
    
    # Yes
    ydotool mousemove --absolute 1094 724
    ydotool click $LEFT_CLICK
    sleep $DELAY
    sleep $DELAY
done
