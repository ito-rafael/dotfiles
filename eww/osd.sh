#!/usr/bin/env bash
# define notification duration in seconds
TIMEOUT=1
# get setting to control via argument (volume, mic, brightness, gamma, backlit)
ATTRIBUTE=$1

case "$ATTRIBUTE" in

volume)
    RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    VALUE=$(echo "$RAW" | awk '{print int($2 * 100)}')
    if [[ "$RAW" == *"[MUTED]"* ]] || [ "$VALUE" -eq "0" ]; then
        ICON="/home/rafael/.config/icon/vol-mute.png"
    elif [ "$VALUE" -lt "33" ]; then
        ICON="/home/rafael/.config/icon/vol-low.png"
    elif [ "$VALUE" -lt "66" ]; then
        ICON="/home/rafael/.config/icon/vol-med.png"
    else
        ICON="/home/rafael/.config/icon/vol-high.png"
    fi
    ;;

mic)
    RAW=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
    VALUE=$(echo "$RAW" | awk '{print int($2 * 100)}')
    if [[ "$RAW" == *"[MUTED]"* ]] || [ "$VALUE" -eq "0" ]; then
        ICON="/home/rafael/.config/icon/mic-mute.svg"
    else
        ICON="/home/rafael/.config/icon/mic.svg"
    fi
    ;;

brightness)
    MAX=$(brightnessctl max)
    CURRENT=$(brightnessctl get)
    VALUE=$((CURRENT * 100 / MAX))
    ICON="/home/rafael/.config/icon/brightness.svg"
    ;;

*)
    echo "Usage: $0 {volume|mic|brightness}"
    exit 1
    ;;

esac

# update generic variables in eww.yuck
eww update osd_value="$VALUE" osd_icon="$ICON"
# open generic OSD window
eww open system_osd

# set sleep timer
PID_FILE="/tmp/eww-osd.pid"
# kill previous timer if it exists
if [ -f "$PID_FILE" ]; then
    kill $(cat "$PID_FILE") 2>/dev/null
fi

# start new timer
(
    sleep $TIMEOUT
    eww close system_osd
    rm -f "$PID_FILE"
) &

echo $! >"$PID_FILE"
