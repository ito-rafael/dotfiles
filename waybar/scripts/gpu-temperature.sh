#!/usr/bin/env bash
CRITICAL_THRESHOLD=85
temp=""

HWMON=$(find /sys/bus/pci/devices/0000:08:00.0/hwmon/ -name "temp1_input" 2>/dev/null | head -n 1)
if [ -f "$HWMON" ]; then
    raw=$(cat "$HWMON" 2>/dev/null)
    if [ -n "$raw" ]; then
        temp=$((raw / 1000))
    fi

elif command -v nvidia-smi >/dev/null 2>&1; then
    val=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null)
    if [ -n "$val" ]; then
        temp="$val"
    fi
fi

if [ -z "$temp" ]; then
    exit 0
fi

class="normal"
if [ "$temp" -ge "$CRITICAL_THRESHOLD" ]; then
    class="critical"
fi

printf '{"text": "│%d°C", "class": "%s"}\n' "$temp" "$class"
