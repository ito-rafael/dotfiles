#!/usr/bin/env bash

# define levels for AUR updates
LEVEL_1="1"
LEVEL_2="3"
LEVEL_3="5"

# define the interval
DELAY=600  # 600 seconds = 10 minutes

while true; do
    # output the loading state
    echo '{"text": "", "alt": "loading", "class": "loading"}'

    # check for available AUR updates
    # - "Qua":
    #   - "Q": query
    #   - "u": upgrades
    #   - "a": AUR
    UPDATES=$(paru -Qua 2>/dev/null | wc -l)

    # output the final state
    if [ "$UPDATES" -lt "$LEVEL_1" ]; then
        echo '{"text": "'"$UPDATES"'", "alt": "zero", "class": "zero"}'
    elif [ "$UPDATES" -ge "$LEVEL_1" ] && [ "$UPDATES" -lt "$LEVEL_2" ]; then
        echo '{"text": "'"$UPDATES"'", "alt": "low", "class": "low"}'
    elif [ "$UPDATES" -ge "$LEVEL_2" ] && [ "$UPDATES" -lt "$LEVEL_3" ]; then
        echo '{"text": "'"$UPDATES"'", "alt": "medium", "class": "medium"}'
    else
        echo '{"text": "'"$UPDATES"'", "alt": "high", "class": "high"}'
    fi

    sleep $DELAY
done
