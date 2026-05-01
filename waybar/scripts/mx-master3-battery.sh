#!/usr/bin/env bash

# define batery levels
LEVEL_1="100%"  # Full
LEVEL_2="50%"   # Good/Normal
LEVEL_3="20%"   # Low
LEVEL_4="10%"   # Critical

# get current battery level
BATTERY_LEVEL=$(solaar show 'MX Master 3' 2>/dev/null | tail -n1 | awk '/Battery/ {print $2}' | tr -d ',')

case "$BATTERY_LEVEL" in
    $LEVEL_1)
        echo '{"text": "'$BATTERY_LEVEL'", "alt": "full", "class": "full"}' ;;
    $LEVEL_2)
        echo '{"text": "'$BATTERY_LEVEL'", "alt": "good", "class": "good"}' ;;
    $LEVEL_3)
        echo '{"text": "'$BATTERY_LEVEL'", "alt": "low", "class": "low"}' ;;
    $LEVEL_4)
        echo '{"text": "'$BATTERY_LEVEL'", "alt": "critical", "class": "critical"}' ;;
    *) exit 1 ;;
esac
