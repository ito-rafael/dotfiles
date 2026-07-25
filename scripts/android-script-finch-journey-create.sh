#!/usr/bin/env bash
#
# description:
#   script to create fake journeys and quests in Finch using scrcpy to mirror the phone and ydotool to perform the clicks.
#
# prerequisites:
#   - adb
#   - scrcpy
#   - ydotool
#
# Finch status:
#   - Home screen

LEFT_CLICK=0xC0
#DELAY=1.5
DELAY=2.0

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
    
    # "+" icon
    ydotool mousemove --absolute 1154 148
    ydotool click $LEFT_CLICK
    sleep $DELAY
    
    # Start a new Journey
    ydotool mousemove --absolute 975 249
    ydotool click $LEFT_CLICK
    sleep $DELAY
    
    # type number
    ydotool type $NUMBER
    sleep $DELAY
    
    # Save
    ydotool mousemove --absolute 961 494
    ydotool click $LEFT_CLICK
    sleep $DELAY
    
    # "Add a new goal"
    ydotool mousemove --absolute 964 865
    ydotool click $LEFT_CLICK
    sleep $DELAY

    # type number
    ydotool type $NUMBER
    sleep $DELAY

    # Save
    ydotool mousemove --absolute 1092 484
    ydotool click $LEFT_CLICK
    sleep $DELAY
    
    # Go back to main page
    ydotool mousemove --absolute 756 149
    ydotool click $LEFT_CLICK
    sleep $DELAY
    
    # Start Journey
    ydotool mousemove --absolute 975 1036
    ydotool click $LEFT_CLICK
    sleep $DELAY
    
    # Done
    ydotool mousemove --absolute 962 1036
    ydotool click $LEFT_CLICK
    sleep $DELAY
    sleep $DELAY
done
