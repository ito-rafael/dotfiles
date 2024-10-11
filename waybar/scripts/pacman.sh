#!/usr/bin/env bash

# check for available updates
UPDATES=$(checkupdates | wc -l)

# define levels
LEVEL_1="100"
LEVEL_2="200"

if [ $UPDATES -lt $LEVEL_1 ]; then
    echo '{"text": "'$UPDATES'", "alt": "low", "class": "low"}'
elif [ $UPDATES -ge $LEVEL_1 ] && [ $UPDATES -lt $LEVEL_2 ]; then
    echo '{"text": "'$UPDATES'", "alt": "medium", "class": "medium"}'
else
    echo '{"text": "'$UPDATES'", "alt": "high", "class": "high"}'
fi
