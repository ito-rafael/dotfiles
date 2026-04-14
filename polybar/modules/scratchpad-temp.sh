#!/usr/bin/env bash

ID=$1
COLOR=$2
GRAY=555
SCRATCHPAD_TEMP='/tmp/scratchpad_pid_'$ID'.tmp'

if [ -f $SCRATCHPAD_TEMP ]; then
    echo "%{F#$COLOR}%{F-}"
else
    echo "%{F#$GRAY}%{F-}"
fi
