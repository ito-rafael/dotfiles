#!/usr/bin/env bash

ID=$1
SCRATCHPAD_TEMP='/tmp/scratchpad_pid_'$ID'.tmp'

if [ -f $SCRATCHPAD_TEMP ]; then
    printf '{"text": "", "class": "enabled"}';
else
	printf '{"text": ""}';
fi
