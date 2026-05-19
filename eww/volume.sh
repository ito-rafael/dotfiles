#!/usr/bin/env bash

# define notification duration in seconds
TIMEOUT=1

# get the current volume
RAW_VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
VOLUME=$(echo "$RAW_VOLUME" | awk '{print int($2 * 100)}')

# set icon according to volume level
if [[ "$RAW_VOLUME" == *"[MUTED]"* ]] || [ "$VOLUME" -eq "0" ]; then
    ICON="/home/rafael/.config/icon/vol-mute.png"
elif [ "$VOLUME" -lt "33" ]; then
    ICON="/home/rafael/.config/icon/vol-low.png"
elif [ "$VOLUME" -lt "66" ]; then
    ICON="/home/rafael/.config/icon/vol-med.png"
else
    ICON="/home/rafael/.config/icon/vol-high.png"
fi

# set new values into the Eww variables
eww update volume="$VOLUME" icon="$ICON"
# open the window (if it isn't already open)
eww open volume_osd

# set sleep timer
PID_FILE="/tmp/eww-volume.pid"

# kill previous timer if it exists
if [ -f "$PID_FILE" ]; then
    kill $(cat "$PID_FILE") 2>/dev/null
fi

# start new timer
(
    sleep $TIMEOUT
    eww close volume_osd
    rm -f "$PID_FILE"
) &

echo $! > "$PID_FILE"
