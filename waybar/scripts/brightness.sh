#!/usr/bin/env bash

STEP=1
ACTION="$1"

STATE_FILE="/tmp/wb_brightness_state"
APPLIED_FILE="/tmp/wb_brightness_applied"
CACHE_FILE="/tmp/wb_ddcci_devices"
LOCK_FILE="/tmp/wb_brightness.lock"

# pure bash device caching (no "ls" or "grep" forks)
if [ ! -f "$CACHE_FILE" ]; then
    # look for ddcci devices using pure bash globbing
    shopt -s nullglob
    ddcci_dirs=(/sys/class/backlight/*ddcci*)
    if [ ${#ddcci_dirs[@]} -gt 0 ]; then
        # extract just the folder names and cache them
        printf "%s\n" "${ddcci_dirs[@]##*/}" > "$CACHE_FILE"
    else
        echo "laptop" > "$CACHE_FILE"
    fi
fi
# read array instantly into memory
mapfile -t DEVICES < "$CACHE_FILE"

# get current target (pure bash string manipulation, no "awk" or "tr")
if [ ! -f "$STATE_FILE" ]; then
    if [ "${DEVICES[0]}" != "laptop" ]; then
        RAW=$(brightnessctl --device="${DEVICES[0]}" -m)
    else
        RAW=$(brightnessctl -m)
    fi
    IFS=',' read -ra ADDR <<< "$RAW"
    CUR="${ADDR[3]%\%}"  # strips the trailing "%" instantly
else
    read -r CUR < "$STATE_FILE"
fi

# calculate new target
if [ "$ACTION" == "up" ]; then
    ((CUR += STEP))
elif [ "$ACTION" == "down" ]; then
    ((CUR -= STEP))
fi

# clamp bounds between 0 and 100
if (( CUR > 100 )); then CUR=100; fi
if (( CUR < 0 )); then CUR=0; fi

# save to RAM (tmpfs)
echo "$CUR" > "$STATE_FILE"

# asynchronous background worker
# wrap in ( ) & disown so it detaches from Waybar instantly
(
    # use flock to ensure only one background worker ever touches the hardware at a time
    exec 200>"$LOCK_FILE"
    if flock -n 200; then
        while true; do
            read -r TARGET < "$STATE_FILE"
            read -r APPLIED < "$APPLIED_FILE" 2>/dev/null || APPLIED="-1"

            # if the hardware is caught up to the scroll wheel, exit the worker
            if (( TARGET == APPLIED )); then
                break
            fi

            # apply to hardware in parallel
            if [ "${DEVICES[0]}" != "laptop" ]; then
                for dev in "${DEVICES[@]}"; do
                    brightnessctl --device="$dev" set "${TARGET}%" -q &
                done
                wait  # wait for parallel jobs to finish
            else
                brightnessctl set "${TARGET}%" -q
            fi

            # mark this value as successfully sent to hardware
            echo "$TARGET" > "$APPLIED_FILE"

            # tiny pause to let the I2C bus breathe before checking for new scrolls
            sleep 0.05
        done
    fi
) & disown
