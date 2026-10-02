#!/usr/bin/env bash

STEP=1
ACTION="$1"

STATE_FILE="/tmp/wb_brightness_state"
APPLIED_FILE="/tmp/wb_brightness_applied"
CACHE_FILE="/tmp/wb_ddcci_devices"
LOCK_FILE="/tmp/wb_brightness.lock"

#------------------------------
# caching logic
#------------------------------
if [ ! -f "$CACHE_FILE" ]; then
    shopt -s nullglob
    # Look for native laptop backlights first
    native_dirs=(/sys/class/backlight/intel_backlight /sys/class/backlight/amdgpu_bl*)

    if [ ${#native_dirs[@]} -gt 0 ]; then
        echo "laptop" > "$CACHE_FILE"
    else
        # Try ddcutil for external displays
        displays=$(ddcutil detect -t 2>/dev/null | awk '/^Display/ {gsub(/[^0-9]/, "", $2); print $2}')
        if [ -n "$displays" ]; then
            echo "$displays" > "$CACHE_FILE"
        else
            echo "laptop" > "$CACHE_FILE"
        fi
    fi
fi
# Read array instantly into memory
mapfile -t DEVICES < "$CACHE_FILE"

#------------------------------
# reading logic
#------------------------------
if [ ! -f "$STATE_FILE" ]; then
    if [ "${DEVICES[0]}" == "laptop" ]; then
        RAW=$(brightnessctl -m)
        IFS=',' read -ra ADDR <<< "$RAW"
        CUR="${ADDR[3]%\%}"
    else
        # Probing external monitors synchronously is too slow for the scroll wheel.
        # Initialize at 100% on first boot/run if the state file does not exist.
        CUR=100
    fi
else
    read -r CUR < "$STATE_FILE"
fi

#------------------------------
# calculation logic
#------------------------------
if [ "$ACTION" == "up" ]; then
    ((CUR += STEP))
elif [ "$ACTION" == "down" ]; then
    ((CUR -= STEP))
elif [[ "$ACTION" =~ ^[0-9]+$ ]]; then
    # Exact number (e.g., 50)
    CUR="$ACTION"
elif [[ "$ACTION" =~ ^[0-9]+\+$ ]]; then
    # Increase by N (e.g., 5+)
    NUM="${ACTION%+}"  # Strips the trailing "+"
    ((CUR += NUM))
elif [[ "$ACTION" =~ ^[0-9]+\-$ ]]; then
    # Decrease by N (e.g., 5-)
    NUM="${ACTION%-}"  # Strips the trailing "-"
    ((CUR -= NUM))
fi

# Clamp bounds between 0 and 100
if (( CUR > 100 )); then CUR=100; fi
if (( CUR < 0 )); then CUR=0; fi

# Save target to RAM (tmpfs)
echo "$CUR" > "$STATE_FILE"

#------------------------------
# execution logic (asynchronous worker)
#------------------------------
(
    exec 200>"$LOCK_FILE"
    if flock -n 200; then
        while true; do
            read -r TARGET < "$STATE_FILE"
            read -r APPLIED < "$APPLIED_FILE" 2>/dev/null || APPLIED="-1"

            # Exit worker if hardware is caught up
            if (( TARGET == APPLIED )); then
                break
            fi

            # Apply to hardware
            if [ "${DEVICES[0]}" == "laptop" ]; then
                brightnessctl set "${TARGET}%" -q
            else
                # Apply to external monitors sequentially to prevent I2C locks
                for dev in "${DEVICES[@]}"; do
                    ddcutil --noverify --display="$dev" setvcp 10 "$TARGET" >/dev/null 2>&1
                done
            fi

            # Mark this value as successfully sent to hardware
            echo "$TARGET" > "$APPLIED_FILE"
            sleep 0.05
        done
    fi
) & disown
