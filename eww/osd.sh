#!/usr/bin/env bash
# define notification duration in seconds
TIMEOUT=1
# get setting to control via argument (volume, mic, brightness, gamma, backlit)
ATTRIBUTE=$1

case "$ATTRIBUTE" in

volume)
    RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    VALUE=$(echo "$RAW" | awk '{print int($2 * 100)}')
    case "$RAW" in
    *"[MUTED]"*)
        ICON="/home/rafael/.config/icon/vol-mute.png"
        ;;
    *)
        case 1 in
        $((VALUE == 0))) ICON="/home/rafael/.config/icon/vol-mute.png" ;;
        $((VALUE < 33))) ICON="/home/rafael/.config/icon/vol-low.png" ;;
        $((VALUE < 66))) ICON="/home/rafael/.config/icon/vol-med.png" ;;
        *) ICON="/home/rafael/.config/icon/vol-high.png" ;;
        esac
        ;;
    esac
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

gamma)
    CURRENT_TEMP=$(cat /tmp/gamma_temp.tmp)
    MIN_TEMP=2000
    MAX_TEMP=6500

    # map the 2000K~6500K range to a 0-100 percentage for the eww progress bar
    VALUE=$(((CURRENT_TEMP - MIN_TEMP) * 100 / (MAX_TEMP - MIN_TEMP)))

    # safety checks to ensure the progress bar doesn't break if values go out of bounds
    if [ "$VALUE" -lt 0 ]; then VALUE=0; fi
    if [ "$VALUE" -gt 100 ]; then VALUE=100; fi

    # select icon according to current temperature (using case statement)
    case "$CURRENT_TEMP" in
    2000) ICON="/home/rafael/.config/icon/screen-color-temperature/2000.png" ;;
    2500) ICON="/home/rafael/.config/icon/screen-color-temperature/2500.png" ;;
    3000) ICON="/home/rafael/.config/icon/screen-color-temperature/3000.png" ;;
    3500) ICON="/home/rafael/.config/icon/screen-color-temperature/3500.png" ;;
    4000) ICON="/home/rafael/.config/icon/screen-color-temperature/4000.png" ;;
    4500) ICON="/home/rafael/.config/icon/screen-color-temperature/4500.png" ;;
    5000) ICON="/home/rafael/.config/icon/screen-color-temperature/5000.png" ;;
    5500) ICON="/home/rafael/.config/icon/screen-color-temperature/5500.png" ;;
    6000) ICON="/home/rafael/.config/icon/screen-color-temperature/6000.png" ;;
    6500) ICON="/home/rafael/.config/icon/screen-color-temperature/6500.png" ;;
    *) ICON="/home/rafael/.config/icon/screen-color-temperature/6500.png" ;;
    esac
    ;;

backlit)
    # The -d flag targets the keyboard backlight (find your exact name with 'brightnessctl --list' if this fails)
    MAX=$(brightnessctl -d '*kbd_backlight*' max)
    CURRENT=$(brightnessctl -d '*kbd_backlight*' get)
    VALUE=$((CURRENT * 100 / MAX))

    if [ "$VALUE" -eq 0 ]; then
        ICON="/home/rafael/.config/icon/kbd-backlit-off.svg"
    elif [ "$VALUE" -le 50 ]; then
        ICON="/home/rafael/.config/icon/kbd-backlit-low.svg"
    else
        ICON="/home/rafael/.config/icon/kbd-backlit-high.svg"
    fi
    ;;

*)
    echo "Usage: $0 {volume|mic|brightness|gamma|backlit}"
    exit 1
    ;;

esac

# update generic variables in eww.yuck
eww update osd_value="$VALUE" osd_icon="$ICON"

PID_FILE="/tmp/eww-osd.pid"

# If the PID file doesn't exist, or the timer process is dead, the window is closed.
if [ ! -f "$PID_FILE" ] || ! kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    eww open system_osd
fi

# kill previous timer subshell if it exists
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
