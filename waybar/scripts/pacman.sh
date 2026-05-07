#!/usr/bin/env bash

# check for available updates
UPDATES=$(checkupdates | wc -l)

# define levels
LEVEL_1="100"
LEVEL_2="200"

# define the interval
DELAY=600  # 600 seconds = 10 minutes

while true; do
    # output the loading state
    echo '{"text": "", "alt": "loading", "class": "loading"}'

    # check for available updates
    UPDATES=$(checkupdates 2>/dev/null | wc -l)

    # output the final state
    if [ "$UPDATES" -lt "$LEVEL_1" ]; then
        echo '{"text": "'$UPDATES'", "alt": "low", "class": "low"}'
    elif [ "$UPDATES" -ge "$LEVEL_1" ] && [ "$UPDATES" -lt "$LEVEL_2" ]; then
        echo '{"text": "'$UPDATES'", "alt": "medium", "class": "medium"}'
    else
        echo '{"text": "'$UPDATES'", "alt": "high", "class": "high"}'
    fi

    sleep $DELAY
done
