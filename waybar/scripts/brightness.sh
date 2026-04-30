#!/usr/bin/env bash

STEP=1
ACTION="$1"

# Store temporary states in RAM to make them lightning fast
STATE_FILE="/tmp/wb_brightness_state"
CACHE_FILE="/tmp/wb_ddcci_devices"

# 1. CACHE DEVICES (Massive CPU speedup on rapid scrolls)
if [ ! -f "$CACHE_FILE" ]; then
    ls /sys/class/backlight/ | grep ddcci > "$CACHE_FILE" 2>/dev/null || echo "laptop" > "$CACHE_FILE"
fi
DEVICES=$(cat "$CACHE_FILE")

# 2. GET CURRENT BRIGHTNESS
if [ ! -f "$STATE_FILE" ]; then
    # First scroll since boot: fetch from hardware
    if [ "$DEVICES" != "laptop" ]; then
        FIRST_DEV=$(head -n 1 <<< "$DEVICES")
        CUR=$(brightnessctl --device="$FIRST_DEV" -m | awk -F, '{print int($4)}')
    else
        CUR=$(brightnessctl -m | awk -F, '{print int($4)}')
    fi
else
    # Subsequent scrolls: read instantly from RAM
    CUR=$(cat "$STATE_FILE")
fi

# 3. CALCULATE NEW TARGET
if [ "$ACTION" == "up" ]; then
    CUR=$((CUR + STEP))
elif [ "$ACTION" == "down" ]; then
    CUR=$((CUR - STEP))
fi

# Clamp bounds between 0 and 100
if [ "$CUR" -gt 100 ]; then CUR=100; fi
if [ "$CUR" -lt 0 ]; then CUR=0; fi

# Save the new absolute target to RAM
echo "$CUR" > "$STATE_FILE"

# 4. PREVENT I2C LAG
# Instantly kill any backlogged brightnessctl commands from previous scroll ticks
killall -q -9 brightnessctl

# 5. APPLY TO HARDWARE
if [ "$DEVICES" != "laptop" ]; then
    # Workstation: Apply to all DDCCI monitors in parallel
    echo "$DEVICES" | grep -v "laptop" | xargs -P 0 -I {} brightnessctl --device={} set ${CUR}% -q
else
    # Laptop: Apply to native screen
    brightnessctl set ${CUR}% -q
fi
