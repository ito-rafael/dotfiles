#!/usr/bin/env bash
#
# description:
#   script to open gifts from journeys in Finch using scrcpy to mirror the phone and ydotool to perform the clicks.
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

#for NUMBER in {1..100..1}
for NUMBER in {1..69..1}
do
    # Open mystery gift!
    #ydotool mousemove --absolute 961 397  # without "Adventure completed" notification
    #ydotool mousemove --absolute 960 601   # with "Adventure completed" notification
    ydotool mousemove --absolute 960 530   # with "Adventuring" notification
    ydotool click $LEFT_CLICK
    sleep $DELAY

    # choose one of the 3 gift boxes randomly
    BOX=$(echo "$RANDOM % 3" | bc)
    case "${BOX}" in
        "0") GIFT_BOX="815 695" ;;
        "1") GIFT_BOX="959 695" ;;
        "2") GIFT_BOX="1104 695" ;;
    esac
    
    # Choose a gift box to claim your reward!
    ydotool mousemove --absolute $GIFT_BOX
    ydotool click $LEFT_CLICK
    sleep $DELAY

    # Done
    ydotool mousemove --absolute 960 959
    ydotool click $LEFT_CLICK
    sleep $DELAY
done
