#!/usr/bin/env bash

# Check if adb is connected to any device. If not, output empty text to hide the module.
if ! adb get-state >/dev/null 2>&1; then
    echo '{"text": ""}'
    exit 0
fi

# Fetch battery info. Suppress errors just in case.
BATTERY_INFO=$(adb shell dumpsys battery 2>/dev/null)

# Fallback if the command fails for some reason
if [ -z "$BATTERY_INFO" ]; then
    echo '{"text": ""}'
    exit 0
fi

# Extract values. 'tr -d "\r"' is crucial here to remove Android's carriage returns,
# which would otherwise break the JSON payload.
LEVEL=$(echo "$BATTERY_INFO" | grep " level:" | awk '{print $2}' | tr -d '\r')
STATUS=$(echo "$BATTERY_INFO" | grep " status:" | awk '{print $2}' | tr -d '\r')

# Determine the CSS class based on the status code
# 1: Unknown, 2: Charging, 3: Discharging, 4: Not charging, 5: Full
CLASS="discharging"
case $STATUS in
    2) CLASS="charging" ;;
    3) CLASS="discharging" ;;
    4) CLASS="not-charging" ;;
    5) CLASS="full" ;;
    *) CLASS="unknown" ;;
esac

# Override with warning/critical classes if the battery is low and not charging
if [ "$STATUS" != "2" ] && [ "$STATUS" != "5" ]; then
    if [ "$LEVEL" -le 15 ]; then
        CLASS="critical"
    elif [ "$LEVEL" -le 30 ]; then
        CLASS="warning"
    fi
fi

# Define a device icon
DEV_ICON=""

# Define the icon based on status and battery level
if [ "$STATUS" = "2" ]; then
    ICON="$DEV_ICON ⚡"
elif [ "$STATUS" = "5" ]; then
    ICON="$DEV_ICON 🔌"
else
    if [ "$LEVEL" -le 15 ]; then
        ICON="$DEV_ICON 🪫"
    elif [ "$LEVEL" -le 30 ]; then
        ICON="$DEV_ICON  "
    elif [ "$LEVEL" -le 60 ]; then
        ICON="$DEV_ICON  "
    elif [ "$LEVEL" -le 90 ]; then
        ICON="$DEV_ICON  "
    else
        ICON="$DEV_ICON  "
    fi
fi

# Output valid JSON for Waybar
# - text: What actually shows on the bar
# - class: Added to the CSS classes (e.g., #custom-phone-battery.charging)
# - percentage: Can be used by Waybar for styling/formatting
# - tooltip: Information shown on hover
echo "{\"text\": \"$ICON  $LEVEL%\", \"percentage\": $LEVEL, \"class\": \"$CLASS\", \"tooltip\": \"Phone Battery: $LEVEL%\\nStatus: $CLASS\"}"
