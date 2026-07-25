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
    
# hamburger icon
ydotool mousemove --absolute 757 148
ydotool click $LEFT_CLICK
sleep $DELAY

# "My Self-Care Areas"
ydotool mousemove --absolute 849 389
ydotool click $LEFT_CLICK
sleep $DELAY

for NUMBER in {1..100..1}
do
    # scroll down (10x PageDown)
    for i in {0..3..1}
    do
        ydotool key 109:1 109:0
        sleep 1
    done
    
    # "+ Start a new area" icon
    ydotool mousemove --absolute 738 938
    ydotool click $LEFT_CLICK
    sleep $DELAY

    # scroll down (3x PageDown)
    for i in {0..2..1}
    do
        ydotool key 109:1 109:0
        sleep 0.5
    done

    # "+ Create my own area" icon
    ydotool mousemove --absolute 798 980
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
